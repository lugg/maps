#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Serializes static map warmup so only a few live maps exist at a time.
 * Static maps briefly need a live map view to render their snapshot;
 * without throttling, a list mounting many rows creates them all at once
 * and stalls the main thread.
 */
@interface LuggStaticMapWarmupQueue : NSObject

+ (instancetype)sharedQueue;

/// Calls completion when a warmup slot is available (possibly immediately).
- (void)requestSlotForOwner:(id)owner completion:(dispatch_block_t)completion;

/// Removes any pending request for the owner.
- (void)cancelOwner:(id)owner;

/// Frees the owner's slot and starts the next pending warmup.
- (void)releaseSlotForOwner:(id)owner;

@end

NS_ASSUME_NONNULL_END
