//
//  Python.c
//  LibTerm
//
//  Created by Adrian Labbe on 12/14/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

#include "Py_UnixMain.h"

int python3_main(int argc, char **argv) {
    
    const char * pyPath = [[[[[[NSString stringWithUTF8String:"PYTHONPATH="] stringByAppendingString:[NSBundle.mainBundle pathForResource:@"python37" ofType:@"zip"]] stringByAppendingString:@":"] stringByAppendingString:[[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask][0] URLByAppendingPathComponent:@"site-packages3"].path] stringByAppendingString:@":"] stringByAppendingString:NSBundle.mainBundle.bundlePath].UTF8String;
    
    const char * pyHome = [[NSString stringWithUTF8String:"PYTHONHOME="] stringByAppendingString:[NSBundle.mainBundle pathForResource:@"python37" ofType:@"zip"]].UTF8String;
    
    FILE* oldStdin = stdin;
    FILE* oldStdout = stdout;
    FILE* oldStderr = stderr;
    
    stdin = thread_stdin;
    stdout = thread_stdout;
    stderr = stdout;
    
    if (pyPath) {
        putenv((char *)pyPath);
    }
    
    if (pyHome) {
        putenv((char *)pyHome);
    }
    
    int py = _Py_UnixMain(argc, argv);
    
    stdin = oldStdin;
    stdout = oldStdout;
    stderr = oldStderr;
    
    return py;
}
