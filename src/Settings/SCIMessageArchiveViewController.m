#import "SCIMessageArchiveViewController.h"
#import "../Archive/SCIMessageArchive.h"

@interface SCIMessageArchiveViewController ()
@property (nonatomic, copy) NSArray<NSDictionary *> *messages;
@end

@implementation SCIMessageArchiveViewController
- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Local message archive";
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
        style:UIBarButtonItemStylePlain target:self action:@selector(clearArchive:)];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadArchive];
}
- (void)reloadArchive {
    self.messages = [[SCIMessageArchive sharedArchive] deletedMessages];
    if (!self.messages.count) {
        UILabel *empty = [UILabel new];
        empty.text = @"No retained text messages yet.\n\nEnable local copies before opening a chat. Only text observed on this device can be retained; old unsent messages and attachments cannot be recovered.";
        empty.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        empty.textColor = UIColor.secondaryLabelColor;
        empty.numberOfLines = 0;
        empty.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = empty;
    } else {
        self.tableView.backgroundView = nil;
    }
    [self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"Text only · this device · up to 500 snapshots · excluded from backup.\nShared across accounts on this installation. Tap to read/copy; swipe to remove.";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = self.messages[indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    UIListContentConfiguration *content = cell.defaultContentConfiguration;
    content.text = entry[@"text"];
    content.textProperties.numberOfLines = 4;
    NSString *date = [NSDateFormatter localizedStringFromDate:entry[@"capturedAt"]
        dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    content.secondaryText = [NSString stringWithFormat:@"%@ · %@\n%@", date, entry[@"sender"], entry[@"threadID"]];
    content.secondaryTextProperties.numberOfLines = 0;
    cell.contentConfiguration = content;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *text = self.messages[indexPath.row][@"text"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Retained text"
        message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIPasteboard.generalPasteboard.string = text;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (style != UITableViewCellEditingStyleDelete) return;
    [[SCIMessageArchive sharedArchive] removeEntry:self.messages[indexPath.row][@"entryID"]];
    [self reloadArchive];
}
- (void)clearArchive:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear local copies?"
        message:@"This deletes both retained text and pending snapshots on this device."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[SCIMessageArchive sharedArchive] clear];
        [self reloadArchive];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
