import os

env = DefaultEnvironment(ENV=os.environ)
env.AppendUnique(
    CCFLAGS=['-Wall', '-O2', '-std=c99', '-g'],
    LIBS=['m'] )

LISP_LIBS = ['lisp.c', 'cfunc.c', 'gc.c']

env.Default('mlisp', 'test_mlisp')
env.Program('mlisp', ['main.c'] + LISP_LIBS)
env.Program('test_mlisp', ['test.c'] + LISP_LIBS)

env.Command('test', 'test_mlisp', './test_mlisp')

