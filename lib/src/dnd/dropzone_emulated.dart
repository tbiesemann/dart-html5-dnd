part of html5_dnd;

/**
 * Installs emulated dropzone behaviour for browsers that do not (completely)
 * support HTML5 drag and drop events (IE9 and IE10).
 * 
 * Listens to the custom emulated events fired by the emulated draggable.
 */
List<StreamSubscription> _installEmulatedDropzone(Element element, DropzoneGroup group) {
  List<StreamSubscription> subs = new List<StreamSubscription>();
  
  bool draggableAccepted = false;
  
  // -------------------
  // Emulate DragEnter
  // -------------------
  subs.add(element.on[EMULATED_DRAG_ENTER].listen((MouseEvent mouseEvent) {
    // Test if this dropzone accepts the current draggable.
    draggableAccepted = group._draggableAccepted();
    if (!draggableAccepted) return;

    _logger.finest('emulated dragEnter');
    
    if (!element.contains(mouseEvent.relatedTarget)) {
      // Mouse was moved from outside and might have skipped some elements. 
      // Must clear the drag over elements.
      _logger.finest('relatedTarget is not a child of element having the listener, mouse was moved from outside.');
      currentDragOverElements.clear();
    }
    
    group._handleDragEnter(element, mouseEvent);
  }));
  
  // -------------------
  // Emulate DragOver
  // -------------------
  subs.add(element.on[EMULATED_DRAG_OVER].listen((MouseEvent mouseEvent) {
    if (!draggableAccepted) return;
    
    // Related target is the actual element under the mouse.
    if (mouseEvent.relatedTarget != null && mouseEvent.relatedTarget is Element) {
      Element elementUnderMouse = mouseEvent.relatedTarget;
      
      // Set a new cursor (old cursor will be restored by EmulatedDraggableGroup)
      switch(currentDraggableGroup.dropEffect) {
        case DraggableGroup.DROP_EFFECT_MOVE:
          elementUnderMouse.style.cursor = 'move';
          break;
        case DraggableGroup.DROP_EFFECT_COPY:
          elementUnderMouse.style.cursor = 'copy';
          break;
        case DraggableGroup.DROP_EFFECT_LINK:
          elementUnderMouse.style.cursor = 'alias';
          break;
        default:
          elementUnderMouse.style.cursor = 'no-drop';
      }
    }
    group._handleDragOver(element, mouseEvent);
  }));
  
  // -------------------
  // Emulate DragLeave
  // -------------------
  subs.add(element.on[EMULATED_DRAG_LEAVE].listen((MouseEvent mouseEvent) {
    if (!draggableAccepted) return;
    
    _logger.finest('emulated dragLeave');
    group._handleDragLeave(element, mouseEvent);
  }));
  
  // -------------------
  // Emulate Drop
  // -------------------
  subs.add(element.on[EMULATED_DROP].listen((MouseEvent mouseEvent) {
    if (!draggableAccepted || !group._dropAllowed()) return;
    
    _logger.finest('emulated drop');
    group._handleDrop(element, mouseEvent);
  }));
  
  return subs;
}

/**
 * Returns true if either [target1] is an ancestor of [target2] or 
 * [target2] is a an ancestor of [target1].
 */
bool _areAncestors(EventTarget target1, EventTarget target2) {
  if (target1 is! Element || target2 is! Element) return false;
  
  return target1.contains(target2) || target2.contains(target1);
}