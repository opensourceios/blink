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

#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#import "Session.h"
#import "fterm.h"


int makeargs(const char *args, char ***aa)
{
  char *buf = strdup(args);
  int c = 1;
  char *delim;
  char **argv = calloc(c, sizeof(char *));

  argv[0] = buf;

  while ((delim = strchr(argv[c - 1], ' '))) {
    argv = realloc(argv, (c + 1) * sizeof(char *));
    argv[c] = delim + 1;
    *delim = 0x00;
    c++;
  }

  argv = realloc(argv, (c + 1) * sizeof(char *));
  argv[c] = NULL;

  *aa = argv;

  return c;
}

void *run_session(void *params)
{
  SessionParams *p = (SessionParams *)params;
  // Object back to ARC
  Session *session = (Session *)CFBridgingRelease(p->session);
  char **argv;
  int argc = makeargs(p->args, &argv);
  [session main:argc argv:argv];
  free(argv);
  free(params);

  //if (!p->attached) {
  [session.stream close];
  //}

  session.stream = nil;
  return NULL;
}

@implementation TermStream

- (void)close
{
  if (_in) {
    fclose(_in);
    _in = NULL;
  }
  if (_out) {
    fclose(_out);
    _out = NULL;
  }
  if (_err) {
    fclose(_err);
    _err = NULL;
  }
  _sz = NULL;
  _control = nil;
}

@end

@implementation Session

- (id)initWithStream:(TermStream *)stream
{
  self = [super init];

  if (self) {
    _stream = [[TermStream alloc] init];
    _stream.in = fdopen(dup(fileno(stream.in)), "r");

    // If there is no underlying descriptor (writing to the WV), then duplicate the fterm.
    _stream.out = fdopen(dup(fileno(stream.out)), "w");
    if (_stream.out == NULL) {
      _stream.out = fterm_open(stream.control.terminal, 0);
    }
    _stream.err = fdopen(dup(fileno(stream.err)), "w");
    if (_stream.err == NULL) {
      _stream.err = fterm_open(stream.control.terminal, 0);
    }

    _stream.control = stream.control;
    _stream.sz = stream.sz;
  }

  return self;
}

- (void)executeWithArgs:(NSString *)args
{
  SessionParams *params = malloc(sizeof(SessionParams));
  // Pointer to our struct, we are responsible of release
  params->session = CFBridgingRetain(self);
  params->args = [args UTF8String];
  params->attached = false;

  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
  pthread_create(&_tid, &attr, run_session, params);
}

- (void)executeAttachedWithArgs:(NSString *)args
{
  SessionParams *params = malloc(sizeof(SessionParams));
  // Pointer to our struct, we are responsible of release
  params->session = CFBridgingRetain(self);
  params->args = [args UTF8String];
  params->attached = true;

  pthread_create(&_tid, NULL, run_session, params);
  pthread_join(_tid, NULL);
}

@end
