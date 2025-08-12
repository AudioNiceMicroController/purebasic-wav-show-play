# purebasic-wav-show-play

## There are 2 test file with libs for
- win x86
- mac silicon

## A wav file is needed
You have to create a "_.wav" file in this directory to test

## The problem (see capture.mov)
res.i=dessine(monCanva, pos, moyennes())
near line 290, will crash but not with the content of this procedure (comment mode below this line "res.i=dessine(monCanva, pos, moyennes())")

## Question
Why and how to keep the call procedure ?