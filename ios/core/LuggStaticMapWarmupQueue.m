#import "LuggStaticMapWarmupQueue.h"

static const NSUInteger kMaxConcurrentWarmups = 2;
// Slot is force-released if a map never finishes rendering (e.g. offline)
// so it can't starve the queue. The live map is left in place.
static const int64_t kWarmupTimeoutSeconds = 10;

@interface LuggWarmupRequest : NSObject
@property(nonatomic, weak) id owner;
@property(nonatomic, copy) dispatch_block_t completion;
@end

@implementation LuggWarmupRequest
@end

@implementation LuggStaticMapWarmupQueue {
  NSMutableArray<LuggWarmupRequest *> *_pending;
  NSHashTable<id> *_active;
}

+ (instancetype)sharedQueue {
  static LuggStaticMapWarmupQueue *queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = [[LuggStaticMapWarmupQueue alloc] init];
  });
  return queue;
}

- (instancetype)init {
  if (self = [super init]) {
    _pending = [NSMutableArray array];
    _active = [NSHashTable weakObjectsHashTable];
  }
  return self;
}

- (void)requestSlotForOwner:(id)owner completion:(dispatch_block_t)completion {
  LuggWarmupRequest *request = [[LuggWarmupRequest alloc] init];
  request.owner = owner;
  request.completion = completion;
  [_pending addObject:request];
  [self drain];
}

- (void)cancelOwner:(id)owner {
  NSMutableArray<LuggWarmupRequest *> *remaining = [NSMutableArray array];
  for (LuggWarmupRequest *request in _pending) {
    if (request.owner != nil && request.owner != owner) {
      [remaining addObject:request];
    }
  }
  _pending = remaining;
}

- (void)releaseSlotForOwner:(id)owner {
  if (![_active containsObject:owner])
    return;
  [_active removeObject:owner];
  [self drain];
}

- (void)drain {
  while (_active.count < kMaxConcurrentWarmups && _pending.count > 0) {
    LuggWarmupRequest *request = _pending.firstObject;
    [_pending removeObjectAtIndex:0];
    id owner = request.owner;
    if (!owner)
      continue;
    [_active addObject:owner];
    [self scheduleTimeoutForOwner:owner];
    request.completion();
  }
}

- (void)scheduleTimeoutForOwner:(id)owner {
  __weak LuggStaticMapWarmupQueue *weakSelf = self;
  __weak id weakOwner = owner;
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, kWarmupTimeoutSeconds * NSEC_PER_SEC),
      dispatch_get_main_queue(), ^{
        id strongOwner = weakOwner;
        if (strongOwner) {
          [weakSelf releaseSlotForOwner:strongOwner];
        }
      });
}

@end
