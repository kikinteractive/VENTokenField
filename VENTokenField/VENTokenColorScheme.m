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
    self.highlightedTextColor = [UIColor grayColor];
    
    self.backgroundColor = [UIColor darkGrayColor];
    self.highlightedBackgroundColor = [UIColor lightGrayColor];
    
    self.deleteButtonBackgroundColor = [UIColor lightGrayColor];
    self.highlightedDeleteButtonBackgroundColorColor = [UIColor darkGrayColor];
    
    return self;
}

@end
