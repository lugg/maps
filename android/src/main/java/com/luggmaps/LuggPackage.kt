package com.luggmaps

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class LuggPackage : ReactPackage {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> =
    listOf(LuggMapViewManager(), LuggMarkerViewManager(), LuggMapWrapperViewManager(), LuggPolylineViewManager())
}
