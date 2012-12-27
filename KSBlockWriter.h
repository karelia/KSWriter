//
//  KSBlockWriter.h
//  Sandvox
//
//  Created by Mike on 27/12/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "KSWriter.h"


@interface KSBlockWriter : NSObject <KSWriter>
{
  @private
    void    (^_block)(NSString *);
}

// The block is called for each string to be written
- (id)initWithBlock:(void (^)(NSString *string))block;

@end
