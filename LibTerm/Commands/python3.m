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

int python3_main(int argc, char **argv) {
    
    const char * pyPath = [[NSString stringWithUTF8String:"PYTHONPATH="] stringByAppendingString:[NSBundle.mainBundle pathForResource:@"python37" ofType:@"zip"]].UTF8String;
    
    FILE* oldStdin = stdin;
    FILE* oldStdout = stdout;
    FILE* oldStderr = stderr;
    
    stdin = thread_stdin;
    stdout = thread_stdout;
    stderr = stdout;
    
    if (pyPath) {
        putenv(pyPath);
    }
    
    int py = _Py_UnixMain(argc, argv);
    
    stdin = oldStdin;
    stdout = oldStdout;
    stderr = oldStderr;
    
    return py;
}
