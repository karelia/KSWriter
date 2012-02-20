//  Created by Sam Deane on 20/02/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.

#import <SenTestingKit/SenTestingKit.h>

@interface KSWriterTestCase : SenTestCase

@property (strong, nonatomic) id dynamicTestParameter;
@property (strong, nonatomic) NSString* dynamicTestName;

+ (id)testCaseWithSelector:(SEL)selector param:(id)param;
+ (id)testCaseWithSelector:(SEL)selector param:(id)param name:(NSString*)name;

- (void)assertString:(NSString*)string1 matchesString:(NSString*)string2;

@end
