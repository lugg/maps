package com.luggmaps

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class LuggPackage : ReactPackage {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> =
    listOf(LuggGoogleMapViewManager(), LuggMarkerViewManager(), LuggMapWrapperViewManager(), LuggPolylineViewManager())

  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> = emptyList()
}
