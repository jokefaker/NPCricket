//
//  NPGitlabIssueHandler.m
//  Pods
//
//  Created by 周国勇 on 4/13/16.
//
//

#import "NPGitlabIssueHandler.h"
#import <UIKit/UIKit.h>
#import "AFNetworking.h"

@interface NPGitlabIssueHandler ()

@property (strong, nonatomic) NSString *privateKey;
@property (strong, nonatomic) NSString *projectId;
@property (strong, nonatomic) NSString *baseUrl;
@property (strong, nonatomic) AFHTTPSessionManager *manager;

@end

@implementation NPGitlabIssueHandler

+ (instancetype)handlerWithPrivateKey:(NSString *)privateKey projectId:(NSString *)projectId baseUrl:(NSString *)baseUrl {
    return [[[self class] alloc] initWithPrivateKey:privateKey projectId:projectId baseUrl:baseUrl];
}

- (instancetype)initWithPrivateKey:(NSString *)privateKey projectId:(NSString *)projectId baseUrl:(NSString *)baseUrl {
    self = [super init];
    if (self) {
        _privateKey = privateKey;
        _projectId = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)projectId, NULL, (CFStringRef) @"!*'/\"();@&=-+$,?%#[]% ", kCFStringEncodingUTF8);
        _baseUrl = baseUrl;
    }
    return self;
}

#pragma mark - NPCricketHandler

- (void)NPCricket_handleFeedback:(NPFeedback *)feedback {
    
    __weak __typeof(&*self)weakSelf = self;
    [self uploadImage:feedback.screenshot completionBlock:^(NSString *markdownText) {
        [weakSelf postIssueWithFeedback:feedback imageMarkdownText:markdownText];
    }];
}

#pragma mark - Gitlab Operation
- (void)uploadImage:(UIImage *)image completionBlock:(void(^)(NSString *markdownText))block{
    
    [self.manager POST:@"uploads" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSData *data = UIImageJPEGRepresentation(image, 0.2);
        [formData appendPartWithFileData:data name:@"file" fileName:@"file.jpg" mimeType:@"image/jpeg"];
    } success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
        if (responseObject) {
            block(responseObject[@"markdown"]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"uploads error:%@", error.localizedDescription);
    }];
}

- (void)postIssueWithFeedback:(NPFeedback *)feedback imageMarkdownText:(NSString *)markdownText {
    if (feedback && markdownText.length != 0) {
        [self.manager POST:@"issues" parameters:@{@"title":@"反馈", @"description":[NSString stringWithFormat:@"%@\n%@", feedback.messageWithMetaData, markdownText]} success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"success:%@", responseObject);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"post issue error:%@", error.localizedDescription);
        }];
    }
}

#pragma mark - Getter
- (AFHTTPSessionManager *)manager {
    if (!_manager) {
        _manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v3/projects/%@/", self.baseUrl, self.projectId]]];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html", @"application/json", @"text/json", @"text/javascript", nil];
        [_manager.requestSerializer setValue:self.privateKey forHTTPHeaderField:@"PRIVATE-TOKEN"];
    }
    return _manager;
}
@end
