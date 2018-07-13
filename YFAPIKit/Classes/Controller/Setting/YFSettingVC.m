//
//  YFSettingVC.m
//  YFAPIKit
//
//  Created by Fynil on 2018/3/15.
//  Copyright © 2018年 Fynil. All rights reserved.
//

#import "YFSettingVC.h"
#import "YFTextViewController.h"

static YFSettingVC *setting;

static NSString *const kEnvironmentKey = @"EnvironmentKey";
static NSString *const kEnvAddressKey = @"llTestServerAddress";

@interface YFSettingVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *settingTb;
@property (nonatomic, strong) NSArray *configArr;

@end

@implementation YFSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.envType = [YFSettingVC environment];
    self.title = @"设置";
    [self.view addSubview:self.settingTb];
}

#pragma mark - delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3 + [self add];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [self environmentInfo].count;
    }
    if (section == 1) {
        return 1;
    }
    if (section == 2 && self.configArr.count > 0) {
        return self.configArr.count;
    }
    if (section == (2 + [self add])) {
        return 2;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"set"];
    if (cell== nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"set"];
    }
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    //环境
    if (indexPath.section == 0) {
        cell.detailTextLabel.text = @"";
        cell.textLabel.text = [[self environmentInfo] objectAtIndex:indexPath.row];
        if (indexPath.row == self.envType) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    //地址
    if (indexPath.section == 1) {
        cell.textLabel.text = @"地址";
        NSString *address = self.testAddress;
        cell.detailTextLabel.text = address.length > 0 ? address : @"请配置测试环境地址";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    //配置
    if (indexPath.section == 2 && self.configArr.count > 0) {
        cell.textLabel.text = self.configArr[indexPath.row][@"name"];
        UISwitch *accessorySwitch = [UISwitch new];
        accessorySwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:self.configArr[indexPath.row][@"key"]];
        accessorySwitch.tag = indexPath.row;
        [accessorySwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = accessorySwitch;
    }
    
    //SDK
    if (indexPath.section == (2 + [self add])) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"检查更新";
            cell.detailTextLabel.text = [@"Demo版本:" stringByAppendingString:[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"关于SDK";
//            cell.detailTextLabel.numberOfLines = 2;
//            cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
            cell.detailTextLabel.text = self.sdkVersion?:@"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //切换环境
    if (indexPath.section == 0) {
        self.envType = indexPath.row;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    }
    //测试环境地址
    if (indexPath.section ==1 && self.envType == EnvironmentTypeTest) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"测试环境地址" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = self.testAddress;
            textField.textAlignment = NSTextAlignmentCenter;
            textField.accessibilityIdentifier = @"testAddrField";
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.placeholder = @"请输入测试环境地址";
            textField.borderStyle = UITextBorderStyleNone;
            textField.keyboardType = UIKeyboardTypeURL;
            textField.textAlignment = NSTextAlignmentCenter;
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *field = alert.textFields.firstObject;
            [[NSUserDefaults standardUserDefaults] setValue:field.text forKey:kEnvAddressKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    if (indexPath.section == (2 + [self add])) {
        //检查更新
        if (indexPath.row == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"YFCheckUpdate" object:nil];
        }
        //关于SDK
        if (indexPath.row == 1) {
            if (self.sdkAbout.length > 0) {
                YFTextViewController *aboutVC = [[YFTextViewController alloc] init];
                aboutVC.fileName = self.sdkAbout;
                [self.navigationController pushViewController:aboutVC animated:YES];
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"环境";
    }
    if (section ==1) {
        return @"测试环境地址，仅对测试环境有效";
    }
    if (section == 2 && self.configArr.count > 0) {
        return @"配置";
    }
    return @"";
}

#pragma mark - private

- (void)switchValueChanged: (UISwitch *)sender {
    NSString *key = [self.configArr objectAtIndex:sender.tag][@"key"];
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)environmentInfo {
    return @[@"正式环境",@"测试环境",@"UAT环境"];
}

- (NSInteger)add {
    return self.configArr.count > 0 ?1:0;
}

+ (void)addConfiguration:(NSString *)configurationName forKey:(NSString *)key {
    if (!(configurationName.length > 0 && key.length > 0)) {
        return;
    }
    NSArray *savedConfigurations = [YFSettingVC defaultSetting].configArr;
    NSMutableArray *mConf = savedConfigurations?savedConfigurations.mutableCopy:@[].mutableCopy;
    NSDictionary *dic = @{@"name":configurationName,@"key":key};
    if (![mConf containsObject:dic]) {
        [mConf addObject:dic];
    }
    [YFSettingVC defaultSetting].configArr = mConf.copy;
}

- (NSString *)stringForFile: (NSString *)file {
    if (!file) return nil;
    NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:@"md"];
    NSString *readMe = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return readMe;
}

#pragma mark - getter

+ (instancetype)defaultSetting {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        setting = [[YFSettingVC alloc] init];
        setting.configArr = nil;
    });
    return setting;
}

+ (EnvironmentType)environment {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kEnvironmentKey];
}

- (NSString *)testAddress {
    NSString *savedAddr = [[NSUserDefaults standardUserDefaults] valueForKey:kEnvAddressKey];
    if (savedAddr.length > 0) {
        return savedAddr;
    }
    [[NSUserDefaults standardUserDefaults] setValue:_testAddress forKey:kEnvAddressKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return _testAddress;
}

+ (BOOL)isDebug {
#ifdef DEBUG
    return YES;
#endif
    return NO;
}

- (void)setEnvType:(EnvironmentType)envType {
    _envType = envType;
    [[NSUserDefaults standardUserDefaults] setInteger:envType forKey:kEnvironmentKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CGRect)tableRect {
    BOOL translucent = self.navigationController.navigationBar.isTranslucent;
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - (translucent?0:64));
    return rect;
}

- (UITableView *)settingTb {
    if (!_settingTb) {
        _settingTb = [[UITableView alloc] initWithFrame:[self tableRect] style:UITableViewStyleGrouped];
        _settingTb.delegate = self;
        _settingTb.dataSource = self;
        _settingTb.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return _settingTb;
}

@end