//
//  QFNetworking.m
//  LoveCar
//
//  Created by apple on 16/4/12.
//  Copyright © 2016年 aichezhonghua. All rights reserved.
//

#import "QFNetworking.h"

@interface QFNetworking ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation QFNetworking

+ (id)sharedInstance {
    static QFNetworking *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
    });
    return sharedInstance;
}

- (void)POST:(NSString *)URLString
  parameters:(id)parameters
    progress:(void (^)(NSProgress *progress))progress
     success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
     failure:(void (^)(NSURLSessionDataTask *task, NSError *error, NSString *errorMsg))failure {
    debugLog(@"当前请求网址为：%@", [mainURL stringByAppendingString:URLString]);
    debugLog(@"当前请求参数为：%@", parameters);

    /**
     *  状态栏菊花
     */
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self.sessionManager POST:[mainURL stringByAppendingString:URLString]
        parameters:parameters
        progress:^(NSProgress *_Nonnull uploadProgress) {
            debugLog(@"---上传进度--- %@", uploadProgress);
            if (progress) {
                progress(uploadProgress);
            }
        }
        success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            // 获取响应头
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            NSDictionary *allHeaders = response.allHeaderFields;
            if ([allHeaders valueForKey:@"t"]) {
                debugLog(@"tttttttttt %@",[allHeaders valueForKey:@"t"]);
                // 设置请求头
                [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",[allHeaders valueForKey:@"t"]] forKey:@"t"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
            }

            debugLog(@"%@", responseObject);
            if (responseObject) {
                if ([[responseObject valueForKey:@"ret"] intValue] == 1) {
                    success(task, responseObject);
                } else {
                    failure(task, nil, nil);
                }
            }

        }
        failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
            if (failure) {
                failure(task, error, error.localizedDescription);
                debugLog(@"网络请求错误：%@", error.localizedDescription);
            }
        }];
}

- (void)GET:(NSString *)URLString
 parameters:(id)parameters
   progress:(void (^)(NSProgress *progress))progress
    success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
    failure:(void (^)(NSURLSessionDataTask *task, NSError *error, NSString *errorMsg))failure {

    NSString *URL = [[URLString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"http"]
                        ? URLString
                        : [mainURL stringByAppendingString:URLString];
    debugLog(@"当前请求网址为：%@", URL);
    debugLog(@"当前请求参数为：%@", parameters);

    /**
     *  状态栏菊花
     */
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self.sessionManager GET:URL
        parameters:parameters
        progress:^(NSProgress *_Nonnull uploadProgress) {
            debugLog(@"---上传进度--- %@", uploadProgress);
            if (progress) {
                progress(uploadProgress);
            }
        }
        success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            // 获取响应头
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            NSDictionary *allHeaders = response.allHeaderFields;
            if ([allHeaders valueForKey:@"t"]) {
                debugLog(@"tttttttttt %@",[allHeaders valueForKey:@"t"]);
                // 设置请求头
                [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",[allHeaders valueForKey:@"t"]] forKey:@"t"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
            }
            if (![[URLString substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"http"]) {
                if (responseObject) {
                    if ([[responseObject valueForKey:@"ret"] intValue] == 1) {
                        success(task, responseObject);
                    } else {
                        failure(task, nil, [responseObject valueForKey:@"ret"]);
                    }
                }
            } else {
                if (responseObject) {
                    success(task, responseObject);
                }
            }

        }
        failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
            if (failure) {
                failure(task, error, error.localizedDescription);
                debugLog(@"网络请求错误：%@", error.localizedDescription);
            }
        }];
}

- (void)POST:(NSString *)URLString
  parameters:(id)parameters
      images:(NSMutableArray *)images
    formData:(void (^)(id<AFMultipartFormData> formData))block
    progress:(void (^)(NSProgress *progress))progress
     success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
     failure:(void (^)(NSURLSessionDataTask *task, NSError *error, NSString *errorMsg))failure {
    
    debugLog(@"当前请求网址为：%@", [mainURL stringByAppendingString:URLString]);
    debugLog(@"当前请求参数为：%@", parameters);

    /**
     *  状态栏菊花
     */
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    self.sessionManager.requestSerializer.timeoutInterval = 20;
    self.sessionManager.responseSerializer.acceptableContentTypes =
        [NSSet setWithObjects:@"text/plain", @"multipart/form-data", @"application/json", @"text/html", @"image/jpeg",
                              @"image/png", @"application/octet-stream", @"text/json", nil];
    // 在parameters里存放照片以外的对象
    [self.sessionManager POST:[mainURL stringByAppendingString:URLString]
        parameters:parameters
        constructingBodyWithBlock:^(id<AFMultipartFormData> _Nonnull formData) {
            // formData: 专门用于拼接需要上传的数据,在此位置生成一个要上传的数据体
            block(formData);
            if (images) {
                for (int i = 0; i < images.count; i++) {
                    NSData *imageData = images[i];

                    // 在网络开发中，上传文件时，是文件不允许被覆盖，文件重名
                    // 要解决此问题，
                    // 可以在上传时使用当前的系统事件作为文件名
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    // 设置时间格式
                    [formatter setDateFormat:@"yyyyMMddHHmmss"];
                    NSString *dateString = [formatter stringFromDate:[NSDate date]];
                    NSString *name = [NSString stringWithFormat:@"image%d", i + 1];
                    NSString *fileName = [NSString stringWithFormat:@"%@%d.jpg", dateString, i + 1];

                    /*
                     *该方法的参数
                     1. appendPartWithFileData：要上传的照片[二进制流]
                     2. name：对应网站上[upload.php中]处理文件的字段（比如upload）
                     3. fileName：要保存在服务器上的文件名
                     4. mimeType：上传的文件的类型
                     */
                    [formData appendPartWithFileData:imageData name:name fileName:fileName mimeType:@"image/jpeg"];
                }
            }
        }
        progress:^(NSProgress *_Nonnull uploadProgress) {

            debugLog(@"---上传进度--- %@", uploadProgress);
            progress(uploadProgress);

        }
        success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {

            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            // 获取响应头
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            NSDictionary *allHeaders = response.allHeaderFields;
            if ([allHeaders valueForKey:@"t"]) {
                debugLog(@"tttttttttt %@",[allHeaders valueForKey:@"t"]);
                // 设置请求头
                [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",[allHeaders valueForKey:@"t"]] forKey:@"t"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
            }
            if (responseObject) {
                if ([[responseObject valueForKey:@"ret"] intValue] == 1) {
                    success(task, responseObject);
                } else {
                    failure(task, nil, nil);
                }
            }

        }
        failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {

            failure(task, error, error.localizedDescription);
            debugLog(@"网络请求错误：%@", error.localizedDescription);
        }];
}

//添加证书
- (AFSecurityPolicy *)customSecurityPolicy {
    // /先导入证书
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"aichewang.cer" ofType:nil]; //证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    // AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    // 如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;

    // validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;

    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:certData, nil];

    return securityPolicy;
}

//懒加载
- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        //        [_sessionManager setSecurityPolicy:[self customSecurityPolicy]];
        // 单例初始化时已经初始化
        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        [_sessionManager.requestSerializer setValue:@"GFBiOS" forHTTPHeaderField:@"X-Requested-With"];
        [_sessionManager.requestSerializer setValue:@"2" forHTTPHeaderField:@"f"];
        [_sessionManager.requestSerializer setValue:@"3.5" forHTTPHeaderField:@"appv"];
    }
    
    // 设置请求头
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"t"]) {
        debugLog(@"打印 %@",[[NSUserDefaults standardUserDefaults] valueForKey:@"t"]);
        [_sessionManager.requestSerializer
         setValue:[NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] valueForKey:@"t"]]
         forHTTPHeaderField:@"t"];
    }

    
    return _sessionManager;
}

@end
