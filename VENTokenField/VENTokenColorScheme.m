//
//  VENTokenColorScheme.m
//  Pods
//
//  Created by Natan Rolnik on 08/03/16.
//
//

#import "VENTokenColorScheme.h"

@implementation VENTokenColorScheme

- (instancetype)init
{
    self = [super init];

    if (!self) {
        return nil;
    }
    
    self.textColor = [UIColor whiteColor];
    self.highlightedTextColor = [UIColor yellowColor];
    self.backgroundColor = [UIColor darkGrayColor];
    self.highlightedBackgroundColor = [UIColor lightGrayColor];
    
    return self;
}

@end
