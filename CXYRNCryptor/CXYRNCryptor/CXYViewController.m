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
    
    _resources = @[].mutableCopy;
    
    kCXYWeak(weakSelf);
    _deleteBlock = ^(NSInteger index){
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
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


#pragma mark - tableview delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _resources.count;
}

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if([tableColumn.identifier isEqualToString:@"cxyCell"] )
    {
        cellView.textField.stringValue = [_resources[row] lastPathComponent];
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
    [panel setAllowedFileTypes:@[_extensionTextField.stringValue]];
    [panel setExtensionHidden:YES];
    [panel setCanCreateDirectories:YES];
    [panel beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result){
                 if (result == NSFileHandlingPanelOKButton)
                     {
                         NSString *path = [[[panel URL] URLByDeletingPathExtension] path];
                         
                         NSString *fileName =  [panel.nameFieldStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                         
                         NSString *savePath = nil;
                         if (fileName.length > 0) {
                             NSFileManager *fileManager = [[NSFileManager alloc]init];
                            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
                             savePath = path;
                         } else {
                             savePath = [[[panel URL] URLByDeletingLastPathComponent] path];
                         }
                         
                         _savePathLabel.stringValue = [NSString stringWithFormat:@"save path:\n%@",savePath];
                         NSArray *temps = [_resources copy];
                         for (NSURL *url in temps) {
                             NSData *data = [NSData dataWithContentsOfURL:url];
                             NSError *error;
                             NSData *encryptedData = [RNEncryptor encryptData:data
                                                                 withSettings:kRNCryptorAES256Settings
                                                                     password:_pwdTextField.stringValue
                                                                        error:&error];
                             NSString *filePath = [[savePath stringByAppendingPathComponent:[[url URLByDeletingPathExtension] lastPathComponent]] stringByAppendingPathExtension:_extensionTextField.stringValue];
 
                             if (!error) {
                                 [encryptedData writeToFile:filePath atomically:NO];
                                 NSInteger index = [_resources indexOfObject:url];
                                 !_deleteBlock?:_deleteBlock(index);
                                 NSLog(@"======success encrypt :%@=====",url);
                             }

                             NSLog(@"====%@====",filePath);
                         }
                         

                    }
            }];
}

-(IBAction)addResource:(id)sender {
    
    if (_pwdTextField.stringValue.length == 0) {
        [_pwdTextField becomeFirstResponder];
        return;
    }
    
    NSMutableArray *types = @[].mutableCopy;
    [types addObjectsFromArray:[NSImage imageTypes]];
    [types addObjectsFromArray:@[@"mp3",@"wav",@"plist",@"xml"]];
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanCreateDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel setAllowedFileTypes:types];
    [panel beginSheetModalForWindow:[self.view window] completionHandler: (^(NSInteger result){
        if(result == NSModalResponseOK) {
            NSArray *fileURLs = [panel URLs];
            if (fileURLs.count > 0) {
                _subButton.enabled = YES;
                _encryptButton.enabled = YES;
                [_resources addObjectsFromArray:fileURLs];
                [_resTableView reloadData];
            }
            NSLog(@"fileURLs = %@", fileURLs);
        } })];
}

- (IBAction)subResource:(id)sender {
    
    !_deleteBlock?:_deleteBlock(_resTableView.selectedRow);
}


@end
