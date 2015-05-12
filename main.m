//
//  main.m
//  ios-kext_stat
//
//  Created by huke on 5/11/15.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
// ios kextstat by Cocoa

#import <Foundation/Foundation.h>
#include <dlfcn.h>

void usage();
void show_allKext(void *fcn);
void show_Kext(void *fcn,char *name);

CFDictionaryRef (*OSKextCopyLoadedKextInfo)(CFArrayRef,CFArrayRef);

int main (int argc, const char * argv[])
{
    void *handle = dlopen("write your IOKit Executable files path.from iOS framework cache",RTLD_LAZY);///System/Library/Frameworks/IOKit.framework/IOKit
    //write your IOKit Executable files path.from iOS framework cache
    void *fcn = dlsym(handle,"OSKextCopyLoadedKextInfo");
    if(fcn!=NULL){
        OSKextCopyLoadedKextInfo = (CFDictionaryRef (*)(CFArrayRef,CFArrayRef))fcn;
        int ret;
        if(argc==1)
            usage();
        while((ret = getopt(argc,argv,"ai:"))!=-1){
        switch (ret) {
            case 'a':
                show_allKext(fcn);
                break;
            case 'i':
                show_Kext(fcn,optarg);
                break;
            default:usage();
                break;
        }
        }
    }
    else{
        printf("faild to got dlsym\n");
        return 1;
    }
    return 0;
}

void show_Kext(void *fcn,char *name){
    CFDictionaryRef dicf = OSKextCopyLoadedKextInfo(NULL,NULL);
    NSDictionary *dic_kext = (NSDictionary*)dicf;
    NSDictionary *kext_info = [dic_kext objectForKey:[NSString stringWithUTF8String:name]];
    NSLog(@"%@",kext_info);

}

void show_allKext(void *fcn){
    int i;
    NSInteger kext_count;
    int Index; //OSBundleLoadTag kext的加载序数
    int Refs; //OSBundleRetainCount kext的被引用的次数.如果不为0,这个kext不能被卸载
    long long int Address; //OSBundleLoadAddress 加载在内核空间的地址
    int Size; //OSBundleLoadSize 加载的大小
    int Wired; //OSBundleWiredSize 占有内核空间的大小,注意需要偏移
    NSString *CFName; //CFBundleIdentifier CFBundle名
    //char *CFVersion; //CFBundleVersion Bundle的版本
    //OSBundleMachOHeaders machO的Headers的十六进制.可以用来在内存中查找
    //OSBundleUUID Bundle的UUID
    NSMutableDictionary *index_dic = [[NSMutableDictionary alloc]init];
    
    printf("Index Refs Address             Size       Wired        Name (Version)\n");
    //<Linked Against>
    CFDictionaryRef dicf = OSKextCopyLoadedKextInfo(NULL,NULL);
    NSDictionary *dic_kext = (NSDictionary*)dicf;
    kext_count = [[dic_kext allKeys] count];
    
    for(i=0;i<kext_count;i++) {
        NSDictionary *kext_info = [dic_kext objectForKey:[dic_kext allKeys][i]];
        [index_dic setObject:[kext_info objectForKey:@"CFBundleIdentifier"] forKey:[NSString stringWithFormat:@"%@",[kext_info objectForKey:@"OSBundleLoadTag"]]];
    }
    
    for(i=0;i<kext_count;i++) {
        CFName = [index_dic objectForKey:[NSString stringWithFormat:@"%d",i]];
        if(CFName==nil){
            printf("%d NULL\n",i);
            continue;
        }
        NSDictionary *kext_info = [dic_kext objectForKey:CFName];
        Index = i;
        Refs = [[kext_info objectForKey:@"OSBundleRetainCount"] intValue];
        Address = [[kext_info objectForKey:@"OSBundleLoadAddress"] longLongValue];
        Size = [[kext_info objectForKey:@"OSBundleLoadSize"] intValue];
        Wired = [[kext_info objectForKey:@"OSBundleWiredSize"] intValue];
        char *c_CFName = (char *)[CFName cStringUsingEncoding:NSUTF8StringEncoding];
        printf("%-3d   %-3d  0x%llx  0x%-9x0x%-9x  %s\n",Index,Refs,Address,Size,Wired,c_CFName);
    }
}

void usage(){
    printf("Usage: kextstat(by Cocoa) [-a] show all Kext\n                          [-i kext_name(com.apple.xxx)]\n");
}

