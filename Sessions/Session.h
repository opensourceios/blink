////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

#include <sys/ioctl.h>

#import "TermController.h"


typedef struct SessionParams {
  CFTypeRef session;
  const char *args;
  bool attached;
} SessionParams;

@interface TermStream : NSObject

@property FILE *in;
@property FILE *out;
@property FILE *err;
@property TermController *control;
@property struct winsize *sz;

- (void)close;

@end


@interface Session : NSObject {
  TermStream *_stream;
  pthread_t _tid;
}

@property TermStream *stream;

- (id)init __unavailable;
- (id)initWithStream:(TermStream *)stream;
- (void)executeWithArgs:(NSString *)args;
- (void)executeAttachedWithArgs:(NSString *)args;
- (int)main:(int)argc argv:(char **)argv;
- (void)sigwinch;
- (void)kill;

@end
