//
//  ViewController.m
//  CXYRNCryptor
//
//  Created by chen on 15/5/29.
//  Copyright (c) 2015年 ___CHEN___. All rights reserved.
//

#import "CXYViewController.h"
#import "RNEncryptor.h"

#define kCXYWeak(weakSelf) __weak __typeof(self)weakSelf = self

typedef void(^DeleteBlock)(NSInteger index);

@interface CXYViewController()<NSTableViewDataSource,NSTableViewDelegate>
@property (weak) IBOutlet NSTextField *pwdTextField;
@property (weak) IBOutlet NSTableView *resTableView;
@property (weak) IBOutlet NSTextField *extensionTextField;
@property (weak) IBOutlet NSTextField *savePathLabel;
@property (weak) IBOutlet NSButton *subButton;
@property (weak) IBOutlet NSButton *encryptButton;

@property (strong) NSMutableArray *resources;

@property (copy) DeleteBlock deleteBlock;
@end

@implementation CXYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.resources = @[].mutableCopy;
    kCXYWeak(weakSelf);
    self.deleteBlock = ^(NSInteger index){
        if (weakSelf.resources.count <= index || index < 0) {
            return;
        }
        [weakSelf.resources removeObjectAtIndex:index];
        [weakSelf.resTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideRight];
        if (weakSelf.resources.count == 0) {
            weakSelf.subButton.enabled = NO;
            weakSelf.encryptButton.enabled = NO;
        }
    };
}


#pragma mark - tableview delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.resources.count;
}

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if([tableColumn.identifier isEqualToString:@"cxyCell"] ) {
        cellView.textField.stringValue = [self.resources[row] lastPathComponent];
        return cellView;
    }
    return cellView;
}

#pragma mark IBAction

- (IBAction)encryptResource:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:@"res"];
    [panel setMessage:@"Choose the path to save the document"];
    [panel setAllowsOtherFileTypes:YES];
    [panel setAllowedFileTypes:@[self.extensionTextField.stringValue]];
    [panel setExtensionHidden:YES];
    [panel setCanCreateDirectories:YES];
    [panel beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
             NSString *path = [[[panel URL] URLByDeletingPathExtension] path];
             NSString *fileName =  [panel.nameFieldStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
             NSString *savePath = nil;
             if (fileName.length > 0) {
                 NSFileManager *fileManager = [[NSFileManager alloc]init];
                 NSError *err;
                [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
                 NSLog(@"%@",err);
                 savePath = path;
             } else {
                 savePath = [[[panel URL] URLByDeletingLastPathComponent] path];
             }
             self.savePathLabel.stringValue = [NSString stringWithFormat:@"save path:\n%@",savePath];
             NSArray *temps = [self.resources copy];
             for (NSURL *url in temps) {
                 NSData *data = [NSData dataWithContentsOfURL:url];
                 NSError *error;
                 NSData *encryptedData = [RNEncryptor encryptData:data
                                                     withSettings:kRNCryptorAES256Settings
                                                         password:self.pwdTextField.stringValue
                                                            error:&error];
                 NSString *filePath = [[savePath stringByAppendingPathComponent:[[url URLByDeletingPathExtension] lastPathComponent]] stringByAppendingPathExtension:self.extensionTextField.stringValue];
                 if (!error) {
                     [encryptedData writeToFile:filePath atomically:NO];
                     NSInteger index = [self.resources indexOfObject:url];
                     !self.deleteBlock?:self.deleteBlock(index);
                     NSLog(@"======success encrypt :%@=====",url);
                 }
                 NSLog(@"====%@====",filePath);
             }
        }
    }];
}

-(IBAction)addResource:(id)sender {
    if (self.pwdTextField.stringValue.length == 0) {
        [self.pwdTextField becomeFirstResponder];
        return;
    }
    
    NSMutableArray *types = @[].mutableCopy;
    [types addObjectsFromArray:[NSImage imageTypes]];
    [types addObjectsFromArray:@[@"mp3",@"wav",@"plist",@"xml"]];
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanCreateDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel setAllowedFileTypes:types];
    [panel beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK) {
            NSArray *fileURLs = [panel URLs];
            if (fileURLs.count > 0) {
                self.subButton.enabled = YES;
                self.encryptButton.enabled = YES;
                [self.resources addObjectsFromArray:fileURLs];
                [self.resTableView reloadData];
            }
            NSLog(@"fileURLs = %@", fileURLs);
        }
    }];
}

- (IBAction)subResource:(id)sender {
    !self.deleteBlock?:self.deleteBlock(self.resTableView.selectedRow);
}


@end
