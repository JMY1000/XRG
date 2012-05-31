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
//  XRGListNode.h
//

#import <Foundation/Foundation.h>


@interface XRGListNode : NSObject {
    XRGListNode		*prev;
    XRGListNode		*next;
    id				object;
}

- (XRGListNode *)initWithObject:(id)o;
- (id)object;
- (XRGListNode *)prev;
- (XRGListNode *)next;
- (void)setObject:(id)o;
- (void)setPrev:(XRGListNode *)p;
- (void)setNext:(XRGListNode *)n;

@end
