/* 
 * XRG (X Resource Graph):  A system resource grapher for Mac OS X.
 * Copyright (C) 2002-2009 Gaucho Software, LLC.
 * You can view the complete license in the LICENSE file in the root
 * of the source tree.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

//
//  XRGModuleManager.m
//

#import "XRGModuleManager.h"
#import "XRGGraphWindow.h"

@implementation XRGModuleManager

- (XRGModuleManager *)init {
    allModules = [[NSMutableArray arrayWithCapacity:10] retain];
    displayModules = [[NSMutableArray arrayWithCapacity:10] retain];
    alwaysUpdateModules = [[NSMutableArray arrayWithCapacity:5] retain];
    moduleSeparatorWidth = 2;
    graphOrientationVertical = YES;
    myWindow = nil;
    
    return self;
}

- (XRGModuleManager *)initWithWindow:(XRGGraphWindow *)gw {
    (void)[self init];
    if (gw != nil) {
        myWindow = [gw retain];
    }
    else {
        myWindow = nil;
    }
    return self;
}

- (void)addModule:(XRGModule *)m {
    // if it exists already, then update it based on name
    int i;
    for (i = 0; i < [allModules count]; i++) {
        if ([[[allModules objectAtIndex:i] name] isEqualToString:[m name]]) { // we found the module, update it
            [self updateModule:m];
            return;
        }
    }
    
    // we didn't find it, add it instead
    [allModules addObject:m];
    if ([m isDisplayed]) {
        // find the location that the new module should be added at.
        for (i = 0; i < [displayModules count]; i++) {
            if ([[displayModules objectAtIndex:i] displayOrder] > [m displayOrder]) {
                // this is the spot where we want to insert
                break;
            }
        }
        [displayModules insertObject:m atIndex:i];
        [myWindow checkWindowSize];	
        [myWindow setMinSize:[self getMinSize]];
    }
    if ([m alwaysDoesGraphUpdate]) {
        [alwaysUpdateModules addObject:m];
    }
}

// updates a module based on it's name
- (void)updateModule:(XRGModule *)m {
    int i;
        
    for (i = 0; i < [allModules count]; i++) {
        if ([[[allModules objectAtIndex:i] name] isEqualToString:[m name]]) { // we found the module, update it
			[allModules removeObjectAtIndex:i];
            [allModules addObject:m];
            break;
        }
    }
    
    for (i = 0; i < [displayModules count]; i++) {
        if ([[[displayModules objectAtIndex:i] name] isEqualToString:[m name]]) { // we found the module, update it
			[displayModules removeObjectAtIndex:i];
            break;
        }
    }
    
    if ([m isDisplayed]) {
        // find the location that the new module should be added at.
        for (i = 0; i < [displayModules count]; i++) {
            if ([[displayModules objectAtIndex:i] displayOrder] > [m displayOrder]) {
                // this is the spot where we want to insert
                break;
            }
        }
        [displayModules insertObject:m atIndex:i];
        [myWindow checkWindowSize];
    }
    
    for (i = 0; i < [alwaysUpdateModules count]; i++) {
        if ([[[alwaysUpdateModules objectAtIndex:i] name] isEqualToString:[m name]]) {  // we found the module, update it
            [alwaysUpdateModules removeObjectAtIndex:i];
            break;
        }
    }
    if ([m alwaysDoesGraphUpdate]) {
        [alwaysUpdateModules addObject:m];
    }
    [myWindow setMinSize:[self getMinSize]];
}

- (void)updateModuleWithName:(NSString *)name toReference:(id)graphView {
    XRGModule *m = [self getModuleByName:name];
    [m setReference:graphView];
    
    return;
}

- (void)setModule:(NSString *)name isDisplayed:(bool)yesNo {
    XRGModule *foundModule = nil;
    int i;
     
    // find the module
    for (i = 0; i < [allModules count]; i++) {
        if ([[[allModules objectAtIndex:i] name] isEqualToString:name]) { // we found the module, update it
            foundModule = [allModules objectAtIndex:i];
            break;
        }
    }
    
    if (foundModule != nil) {
        // set the displayed value
        [foundModule setIsDisplayed:yesNo];
        
        // remove the module from the displayed modules
        [displayModules removeObject:foundModule];
        
        // re-add it to the displayed modules if we want to display it
        if (yesNo == YES) {
            // find the location that the new module should be added at.
            for (i = 0; i < [displayModules count]; i++) {
                if ([[displayModules objectAtIndex:i] displayOrder] > [foundModule displayOrder]) {
                    // this is the spot where we want to insert
                    break;
                }
            }
            [displayModules insertObject:foundModule atIndex:i];
            [myWindow checkWindowSize];
            
            // reload data in module if needed
            if ([foundModule doesMin30Update]) [[foundModule reference] min30Update:nil];
            if ([foundModule doesMin5Update])  [[foundModule reference] min5Update:nil];
            if ([foundModule doesGraphUpdate]) [[foundModule reference] graphUpdate:nil];
            if ([foundModule doesFastUpdate])  [[foundModule reference] fastUpdate:nil];
        }
    }
    [myWindow setMinSize:[self getMinSize]];
}


- (XRGModule *)getModuleByName:(NSString *)name {
    int i;
    for (i = 0; i < [allModules count]; i++) {
        if ([[[allModules objectAtIndex:i] name] isEqualToString:name]) { 
            return [allModules objectAtIndex:i];
        }
    }
    
    return nil;
}

- (XRGModule *)getModuleByReference:(id)reference {
    int i;
    for (i = 0; i < [allModules count]; i++) {
        if ([[allModules objectAtIndex:i] reference] == reference) {
            return [allModules objectAtIndex:i];
        }
    }
    
    return nil;
}

- (NSSize)getMinSize {
    int i;

  //  NSLog(@"getting min size");
    
    NSSize minSize = NSMakeSize(0, 0);
        
    if (graphOrientationVertical) {    
        for (i = 0; i < [displayModules count]; i++) {
            if (minSize.width < [(XRGModule *)[displayModules objectAtIndex:i] minWidth]) {
                minSize.width = [(XRGModule *)[displayModules objectAtIndex:i] minWidth];
            }
            if (minSize.height < [(XRGModule *)[displayModules objectAtIndex:i] minHeight]) {
                minSize.height = [(XRGModule *)[displayModules objectAtIndex:i] minHeight];
            }
        }
        if ([myWindow minimized]) {
            minSize.height = [[myWindow appSettings] textRectHeight];
        }
        else {
            minSize.height = [[myWindow appSettings] textRectHeight] + ((int)minSize.height * [displayModules count]) + (moduleSeparatorWidth * [displayModules count]);
        }
    }
    else {
        for (i = 0; i < [displayModules count]; i++) {
            if (minSize.height < [(XRGModule *)[displayModules objectAtIndex:i] minHeight]) {
                minSize.height = [(XRGModule *)[displayModules objectAtIndex:i] minHeight];
            }
            if (minSize.width < [(XRGModule *)[displayModules objectAtIndex:i] minWidth]) {
                minSize.width = [(XRGModule *)[displayModules objectAtIndex:i] minWidth];
            }
        }
        if ([myWindow minimized]) {
            minSize.width = [[myWindow appSettings] textRectHeight];
        }
        else {
            minSize.width = [[myWindow appSettings] textRectHeight] + ((int)minSize.width * [displayModules count]) + (moduleSeparatorWidth * [displayModules count]);
        }
    }
    
    minSize.width  += [myWindow borderWidth] * 2;
    minSize.height += [myWindow borderWidth] * 2;
    
    return minSize;
}

- (void)redisplayModules {
    if (myWindow == nil) {
        NSLog(@"XRGModuleManager.redisplayModules():  Couldn't redisplay modules because I don't have a window object.");
        return;
    }
    
    [[myWindow contentView] setNeedsDisplay:YES];
}

- (NSArray *)moduleList {
	return allModules;
}

- (NSArray *)displayList {
	return displayModules;
}

- (int)numModulesDisplayed {
    int i, count = 0;
    for (i = 0; i < [displayModules count]; i++) {
        if (![[displayModules objectAtIndex:i] isEmptyModule]) {
            count++;
        }
    }
    
    return count;
}

- (void)windowChangedToSize:(NSSize)newSize {
    if ([myWindow minimized]) return;
	
    int i;
    NSSize newGraphSize;
    if (graphOrientationVertical) {
        newGraphSize = NSMakeSize(newSize.width - (2 * [myWindow borderWidth]), 
                                  ((newSize.height - (2 * [myWindow borderWidth]) - [[myWindow appSettings] textRectHeight] - (moduleSeparatorWidth * [self numModulesDisplayed])) / [self numModulesDisplayed]));
    }
    else {
        newGraphSize = NSMakeSize((newSize.width - (2 * [myWindow borderWidth]) - [[myWindow appSettings] textRectHeight] - (moduleSeparatorWidth * [self numModulesDisplayed])) / [self numModulesDisplayed],
                                  newSize.height - (2 * [myWindow borderWidth]));
    }
    
    NSSize zeroSize = NSMakeSize(0,0);
    // Undisplay all the modules
    for (i = 0; i < [allModules count]; i++) {
		XRGModule *m = [allModules objectAtIndex:i];
        if ([m reference] != nil && [m isDisplayed] == NO) {
            [m setCurrentSize:zeroSize];
            [[m reference] setGraphSize:zeroSize];
            [[m reference] setFrameSize:zeroSize];
        }
    }
	
    // Let the modules know they are being resized and modify the frames for the new sizes.
    for (i = 0; i < [displayModules count]; i++) {
        // as long as the reference exists in the module at this index, set the graph sizes, etc.
		XRGModule *m = [displayModules objectAtIndex:i];
        if ([m reference] != nil) {
            [m setCurrentSize:newGraphSize];
            [[m reference] setGraphSize:newGraphSize];
            [[m reference] setFrameSize:newGraphSize];
        }
    }
	
    NSPoint newOriginPoint = NSMakePoint([myWindow borderWidth], [myWindow borderWidth]);
    if (graphOrientationVertical) {
        for (i = [displayModules count] - 1; i >= 0; i--) {
            // as long as the reference exists, update the module
            if ([[displayModules objectAtIndex:i] reference] != nil) {
                [[[displayModules objectAtIndex:i] reference] setFrameOrigin: newOriginPoint];
                newOriginPoint.y += newGraphSize.height + moduleSeparatorWidth;
            }
        }
    }
    else {
        newOriginPoint.x += [[myWindow appSettings] textRectHeight] + moduleSeparatorWidth;
        for (i = 0; i < [displayModules count]; i++) {
            // again, as long as the reference exists, update the module
            if ([[displayModules objectAtIndex:i] reference] != nil) {
                [[[displayModules objectAtIndex:i] reference] setFrameOrigin:newOriginPoint];
                newOriginPoint.x += newGraphSize.width + moduleSeparatorWidth;
            }
        }
    } 
    
    [[myWindow contentView] setNeedsDisplay:YES];
	
	
//    if ([myWindow minimized]) return;
//
//    int i;
//    NSSize newGraphSize;
//	NSSize graphUnitSize;	// This is a 1% slice of the window.
//    if (graphOrientationVertical) {
//        newGraphSize = NSMakeSize(newSize.width - (2 * [myWindow borderWidth]), 
//                                  ((newSize.height - (2 * [myWindow borderWidth]) - [[myWindow appSettings] textRectHeight] - (moduleSeparatorWidth * [self numModulesDisplayed])) / [self numModulesDisplayed]));
//		
//		graphUnitSize = NSMakeSize(newSize.width - (2 * [myWindow borderWidth]),
//								   (newSize.height - (2 * [myWindow borderWidth]) - [[myWindow appSettings] textRectHeight] - (moduleSeparatorWidth * [self numModulesDisplayed])) / 100.f);
//    }
//    else {
//        newGraphSize = NSMakeSize((newSize.width - (2 * [myWindow borderWidth]) - [[myWindow appSettings] textRectHeight] - (moduleSeparatorWidth * [self numModulesDisplayed])) / [self numModulesDisplayed],
//                                  newSize.height - (2 * [myWindow borderWidth]));
//
//		graphUnitSize = NSMakeSize((newSize.width - (2 * [myWindow borderWidth]) - [[myWindow appSettings] textRectHeight] - (moduleSeparatorWidth * [self numModulesDisplayed])) / 100.f,
//								   newSize.height - (2 * [myWindow borderWidth]));
//	}
//    
//    NSSize zeroSize = NSMakeSize(0,0);
//    // Undisplay all the modules
//    NSArray *a = [allModules getArray];
//    for (i = 0; i < [a count]; i++) {
//        if ([[a objectAtIndex:i] reference] != nil && [[a objectAtIndex:i] isDisplayed] == NO) {
//            [[[a objectAtIndex:i] reference] setGraphSize:zeroSize];
//            [[[a objectAtIndex:i] reference] setFrameSize:zeroSize];
//        }
//    }
//           
//	// Do the work of figuring out the new sizes of each module.
//    NSArray *b = [displayModules getArray];
//	float newDimensions[[b count]];		// This array contains the new width/height of the modules (depending on orientation).
//	float oldDimensionSum = 0;			// From the current sizes of the modules.
//	float newDimensionSum;				// From the new window size.
//	
//	// Find out the new dimension sum
//	newDimensionSum = graphOrientationVertical ? newSize.height : newSize.width;
//	newDimensionSum -= (2 * [myWindow borderWidth]) + (moduleSeparatorWidth * [self numModulesDisplayed]) + [[myWindow appSettings] textRectHeight];
//	
//	// Find out the old dimension sum.
//	for (i = 0; i < [b count]; i++) {
//		XRGModule *moduleObj = [b objectAtIndex:i];
//		oldDimensionSum += graphOrientationVertical ? [moduleObj currentSize].height : [moduleObj currentSize].width;
//	}
//	
//	// Our multiplier takes us from the old module size to the new one.
//	float multiplier = newDimensionSum / oldDimensionSum;
//	
//	// Populate our initial newDimensions.
//	for (i = 0; i < [b count]; i++) {
//		XRGModule *moduleObj = [b objectAtIndex:i];
//		float workDimension = graphOrientationVertical ? [moduleObj currentSize].height : [moduleObj currentSize].width;
//		newDimensions[i] = workDimension * multiplier;
//	}
//	
//	// Need to check that after factoring with the multiplier that we don't hit below the minimum size.
//	for (i = 0; i < [b count]; i++) {
//		XRGModule *checkModuleObj = [b objectAtIndex:i];
//		float workDimension = newDimensions[i];
//		float minWorkValue = graphOrientationVertical ? [checkModuleObj minHeight] : [checkModuleObj minWidth];
//		
//		if (workDimension * multiplier < minWorkValue) {
//			// We surpassed the minimum, adjust the module sizes by going through and finding the module with the biggest min size gap.
//			int j;
//			int indexToAdjust = -1;
//			float adjustmentMaxSpan = 0;
//			for (j = 0; j < [b count]; j++) {
//				if (j == i) continue;
//				XRGModule *adjustmentModuleObj = [b objectAtIndex:j];
//				float thisAdjustmentSpan = newDimensions[j] - (graphOrientationVertical ? [adjustmentModuleObj minHeight] : [adjustmentModuleObj minWidth]);
//				
//				if (thisAdjustmentSpan > adjustmentMaxSpan) {
//					indexToAdjust = j;
//					adjustmentMaxSpan = thisAdjustmentSpan;
//				}
//			}
//			
//			if (indexToAdjust == -1) {
//				// We shouldn't get here, but if so, then just shrink past the minimum size.
//			}
//			else {
//				// We found a module to take some space away from.
//				// How much do we subtract from the adjustedModule size?
//				float amountToSubtract = minWorkValue - newDimensions[i];
//				newDimensions[j] = newDimensions[j] - amountToSubtract;
//				newDimensions[i] = minWorkValue;
//			}
//		}
//	}
//	
//    // Let the modules know they are being resized and modify the frames for the new sizes.
//    for (i = 0; i < [b count]; i++) {
//		XRGModule *moduleObj = [b objectAtIndex:i];
//		
//        // as long as the reference exists in the module at this index, set the graph sizes, etc.
//        if ([moduleObj reference] != nil) {
//			NSSize adjustedGraphSize = [moduleObj currentSize];
//			if (graphOrientationVertical) {
//				adjustedGraphSize.width = newGraphSize.width;
//				adjustedGraphSize.height = newDimensions[i];
//			}
//			else {
//				adjustedGraphSize.width = newDimensions[i];
//				adjustedGraphSize.height = newGraphSize.height;
//			}
//			
//            [moduleObj setCurrentSize:adjustedGraphSize];
//            [[moduleObj reference] setGraphSize:adjustedGraphSize];
//            [[moduleObj reference] setFrameSize:adjustedGraphSize];
//        }
//    }
//        
//    NSPoint newOriginPoint = NSMakePoint([myWindow borderWidth], [myWindow borderWidth]);
//    if (graphOrientationVertical) {
//        for (i = [b count] - 1; i >= 0; i--) {
//            // as long as the reference exists, update the module
//            if ([[b objectAtIndex:i] reference] != nil) {
//                [[[b objectAtIndex:i] reference] setFrameOrigin: newOriginPoint];
//				newOriginPoint.y += [[b objectAtIndex:i] currentSize].height + moduleSeparatorWidth;
//            }
//        }
//    }
//    else {
//        newOriginPoint.x += [[myWindow appSettings] textRectHeight] + moduleSeparatorWidth;
//        for (i = 0; i < [b count]; i++) {
//            // again, as long as the reference exists, update the module
//            if ([[b objectAtIndex:i] reference] != nil) {
//                [[[b objectAtIndex:i] reference] setFrameOrigin:newOriginPoint];
//                newOriginPoint.x += [[b objectAtIndex:i] currentSize].width + moduleSeparatorWidth;
//            }
//        }
//    } 
//    
//    [[myWindow contentView] setNeedsDisplay:YES];
}

- (void)graphFontChanged {
    // go through the displayed modules and reset the min size.
    int i, n = [displayModules count];
    
    for (i = 0; i < n; i++) {
        if ([[displayModules objectAtIndex:i] reference]) [[[displayModules objectAtIndex:i] reference] updateMinSize];
    }
    
    if (myWindow != nil) {
        NSSize newMin = [self getMinSize];
        if ([myWindow frame].size.width > newMin.width) 
            newMin.width = [myWindow frame].size.width;
        if ([myWindow frame].size.height > newMin.height) 
            newMin.height = [myWindow frame].size.height;
        [myWindow setWindowSize: newMin];
        [myWindow setMinSize:[self getMinSize]];
        //[self redisplayModules];
    }
}

- (void)min30Update {
//    NSLog(@"min30");
    
    int i;
    int N = [displayModules count];
    id module;
    for (i = 0; i < N; i++) {
        module = [displayModules objectAtIndex:i];
        if ([module doesMin30Update] && [module reference] != nil) {
            [[module reference] min30Update:nil];
        }
    }
}

- (void)min5Update {
//    NSLog(@"min5");
    
    int i;
    int N = [displayModules count];
    id module;
    for (i = 0; i < N; i++) {
        module = [displayModules objectAtIndex:i];
        if ([module doesMin5Update] && [module reference] != nil) {
            [[module reference] min5Update:nil];
        }
    }
}

- (void)graphUpdate {
//    NSLog(@"graph");

    int i;
    int N = [displayModules count];
    id obj;
    for (i = 0; i < N; i++) {
        obj = [displayModules objectAtIndex:i];
        if ([obj doesGraphUpdate] && [obj reference] != nil) {
            [[obj reference] graphUpdate:nil];
        }
    }
    
    for (i = 0; i < [alwaysUpdateModules count]; i++) {
        obj = [alwaysUpdateModules objectAtIndex:i];
        if (![obj isDisplayed] && [obj reference] != nil) {
            [[obj reference] graphUpdate:nil];
        }
    }
}

- (void)fastUpdate {
    //NSLog(@"fast");
    
    int i;
    int N = [displayModules count];
    id obj;
    for (i = 0; i < N; i++) {
        obj = [displayModules objectAtIndex:i];
        if ([obj doesFastUpdate] && [obj reference] != nil) {
            [[obj reference] fastUpdate:nil];
        }
    }
}

- (int)moduleSeparatorWidth {
    return moduleSeparatorWidth;
}

- (void)setModuleSeparatorWidth:(int)width {
    moduleSeparatorWidth = width;
}

- (bool)graphOrientationVertical {
    return graphOrientationVertical;
}

- (void)setGraphOrientationVertical:(bool)onOff {
    graphOrientationVertical = onOff;
}

- (float) resizeModuleNumber:(int)index byDelta:(float)delta {	
	XRGModule *resizeModuleObj = nil, *adjacentModuleObj = nil;
	NSSize newResizeModuleSize, newAdjacentModuleSize;
	
	int incrementer = graphOrientationVertical ? -1 : 1;
	if (graphOrientationVertical) index = [displayModules count] - 1 - index;
	if (index >= 0 && index < [displayModules count]) {
		resizeModuleObj = [displayModules objectAtIndex:index];
		newResizeModuleSize = [resizeModuleObj currentSize];
		
		if (graphOrientationVertical) {
			newResizeModuleSize.height += delta;
			if (newResizeModuleSize.height < [resizeModuleObj minHeight]) {
				delta += [resizeModuleObj minHeight] - newResizeModuleSize.height;
				newResizeModuleSize.height = [resizeModuleObj minHeight]; 
			}
		}
		else {
			newResizeModuleSize.width += delta;
			if (newResizeModuleSize.width < [resizeModuleObj minWidth]) {
				delta -= [resizeModuleObj minWidth] - newResizeModuleSize.width;
				newResizeModuleSize.width = [resizeModuleObj minWidth];
			}
		}
	}
	
	int adjacentIndex = index + incrementer;
	if (adjacentIndex >= 0 && adjacentIndex < [displayModules count]) {
		adjacentModuleObj = [displayModules objectAtIndex:adjacentIndex];
		newAdjacentModuleSize = [adjacentModuleObj currentSize];
		
		if (graphOrientationVertical) {
			newAdjacentModuleSize.height -= delta;
			if (newAdjacentModuleSize.height < [adjacentModuleObj minHeight]) {
				newResizeModuleSize.height -= [adjacentModuleObj minHeight] - newAdjacentModuleSize.height;
				newAdjacentModuleSize.height = [adjacentModuleObj minHeight]; 
			}
		}
		else {
			newAdjacentModuleSize.width -= delta;
			if (newAdjacentModuleSize.width < [adjacentModuleObj minWidth]) {
				newResizeModuleSize.width -= [adjacentModuleObj minWidth] - newAdjacentModuleSize.width;
				newAdjacentModuleSize.width = [adjacentModuleObj minWidth]; 
			}
		}
	}
	
	
	if (resizeModuleObj && adjacentModuleObj) {
		[resizeModuleObj setCurrentSize:newResizeModuleSize];
		[[resizeModuleObj reference] setGraphSize:newResizeModuleSize];
		[[resizeModuleObj reference] setFrameSize:newResizeModuleSize];	
		
		[adjacentModuleObj setCurrentSize:newAdjacentModuleSize];
		[[adjacentModuleObj reference] setGraphSize:newAdjacentModuleSize];
		[[adjacentModuleObj reference] setFrameSize:newAdjacentModuleSize];
	}
	
	int i;
	NSPoint newOriginPoint = NSMakePoint([myWindow borderWidth], [myWindow borderWidth]);
	if (graphOrientationVertical) {
		for (i = [displayModules count] - 1; i >= 0; i--) {
			// as long as the reference exists, update the module
			if ([[displayModules objectAtIndex:i] reference] != nil) {
				[[[displayModules objectAtIndex:i] reference] setFrameOrigin: newOriginPoint];
				newOriginPoint.y += [[displayModules objectAtIndex:i] currentSize].height + moduleSeparatorWidth;
			}
		}
	}
	else {
		newOriginPoint.x += [[myWindow appSettings] textRectHeight] + moduleSeparatorWidth;
		for (i = 0; i < [displayModules count]; i++) {
			// again, as long as the reference exists, update the module
			if ([[displayModules objectAtIndex:i] reference] != nil) {
				[[[displayModules objectAtIndex:i] reference] setFrameOrigin:newOriginPoint];
				newOriginPoint.x += [[displayModules objectAtIndex:i] currentSize].width + moduleSeparatorWidth;
			}
		}
	} 
	
	[[myWindow contentView] setNeedsDisplay:YES];
	
	return delta;
}

- (NSArray *) resizeRects {
	NSMutableArray *resizeRects = [NSMutableArray arrayWithCapacity:[displayModules count]];
	
	int startIndex = 0, doneIndex = 0, incrementer = 1;
    NSPoint originPoint = NSMakePoint([myWindow borderWidth], [myWindow borderWidth]);
	
	if (graphOrientationVertical) {
		startIndex = [displayModules count] - 1;
		doneIndex = 0;
		incrementer = -1;
	}
	else {
		startIndex = 0;
		doneIndex = [displayModules count] - 1;
		originPoint.x += [[myWindow appSettings] textRectHeight] + moduleSeparatorWidth;
		incrementer = 1;
	}
	
	int i;
	for (i = startIndex; i != doneIndex; i += incrementer) {
		// if there is a module object reference, then use this as a display module.
		if ([[displayModules objectAtIndex:i] reference] != nil) {
			NSSize moduleSize = [[displayModules objectAtIndex:i] currentSize];

			if (graphOrientationVertical) {
				originPoint.y += moduleSize.height + moduleSeparatorWidth;
				[resizeRects addObject:[NSValue valueWithRect:NSMakeRect(originPoint.x, originPoint.y - 2, moduleSize.width, moduleSeparatorWidth + 2)]];
			}
			else {
				originPoint.x += moduleSize.width;
				[resizeRects addObject:[NSValue valueWithRect:NSMakeRect(originPoint.x - 2, originPoint.y, moduleSeparatorWidth + 2, moduleSize.height)]];
			}			
		}
	}
	
	return resizeRects;
}

@end
