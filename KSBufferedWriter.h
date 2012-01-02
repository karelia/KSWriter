//
//  KSBufferedWriter.h
//  Sandvox
//
//  Created by Mike on 05/08/2011.
//  Copyright 2011-2012 Karelia Software. All rights reserved.
//

//  A subclass of KSStringWriter that uses super's string writing for its buffering, but passes other output through to another writer


#import "KSStringWriter.h"


@interface KSBufferedWriter : KSStringWriter
{
@private
    id <KSWriter>   _output;
}

- (id)initWithOutputWriter:(id <KSWriter>)stream; // designated initializer

@end
