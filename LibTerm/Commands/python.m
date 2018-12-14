//
//  Python.c
//  LibTerm
//
//  Created by Adrian Labbe on 12/14/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

#include "../../Python/Headers/Python.h"
#include "Py_UnixMain.h"
#import <Foundation/Foundation.h>
#import <ios_system/ios_system.h>

int python_main(int argc, char **argv) {
    
    const char * pyPath = [[NSString stringWithUTF8String:"PYTHONPATH="] stringByAppendingString:[NSBundle.mainBundle pathForResource:@"python37" ofType:@"zip"]].UTF8String;
    
    stdin = thread_stdin;
    stdout = thread_stdout;
    stderr = stdout;
    
    if (pyPath) {
        putenv(pyPath);
    }
    
    return _Py_UnixMain(argc, argv);
}
