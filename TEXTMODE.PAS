Unit Textmode;
{Diese Unit enth�lt n�tzliche Proceduren zum Zeichnen von Men�s im Textmodus}
{Version 1.7 - 20.01.20 }

interface
uses dos;

Function  Detect_VidSeg : word;
Function  atr(fg,bg : byte; blink : boolean) : byte;
Procedure AttrMDA(x,y : byte; underline,blink,bright : boolean);
Procedure ChangeAttr(x,y,atrib : byte);
Procedure Cursor(onoff : boolean);
Procedure Window(xp,yp,xp1,yp1 : word; c,b : byte; shadow : boolean);
Procedure Box(xp,yp,xp1,yp1 : word; foreground, background : byte; slim : boolean);
Procedure SetBorder(Color : Word);
Procedure InitMenuScreen(title : string);
Procedure Centeredline(y,c,b : byte; title : string);
Procedure PutChar(x,y: Byte; ch: Char; fg, bg : byte);
Function  GetChar(x,y: Byte): Char;
Function  GetTextColor(x,y: Byte): Byte;
Function  GetTextBackground(x,y: Byte): Byte;
Procedure Fastwrite(x,y,fg, bg : byte; s : string);
Procedure CenteredText(y,c : byte; s : string);
Function  GetX : byte;
Function  GetY : byte;
Procedure GotoXy(x,y : byte);
Procedure Scrollup(lines,x,y,x1,y1 : byte);
Procedure Scrolldown(lines,x,y,x1,y1 : byte);
Procedure Write(s : string);
Procedure Writeln(s : string);
Procedure Textcolor(c : byte);
Procedure Textbackground(c : byte);
Procedure ClrScr;
Procedure Fill(c : char; attr : byte);
Procedure SetWritePage(p : byte);
Procedure SetViewPage(p : byte);
Procedure ViewBuffer(p : pointer);
Procedure Writeto(p : pointer);
Function  Mouse_detected : boolean;
Function  Mouse_Init : Boolean;
Procedure Mouse_SetHLimits(xmin, xmax : Word);
Procedure Mouse_SetVLimits(ymin, ymax : Word);
Procedure Mouse_Show;
Procedure Mouse_Hide;
Procedure Mouse_Read;
Procedure Mouse_SetPos(x, y : Byte);
Procedure ShadowScreen;

type
  mousedata     = record
   nb,b         : byte;
   x,y          : word;
  end;


var
 mi             : pointer;
 mouse          : mousedata;
 mouse_there    : boolean;
 page,tc,tbc    : byte;
 writeseg,
 viewseg,
 vidseg          : word;


implementation

Function Detect_VidSeg : word;
begin
 if Mem[$0000:$0449] = 7 then Detect_VidSeg := $B000
 else Detect_VidSeg := $B800;
end;


Function atr(fg,bg : byte; blink : boolean) :byte;
var a : byte;
begin
 if VidSeg = $B800 then {Color display}
 begin
  a := fg or (bg shl 4);
  if not blink then a := a and not (1 shl 7);
 end
 else
 begin
   a := 7;
 end;
 atr := a;
end;


Procedure ChangeAttr(x,y,atrib : byte);
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;
  mem[writeseg:(((y*80)+x) shl 1)+1]:=atrib;
end;

Procedure AttrMDA(x,y : byte; underline,blink,bright : boolean);
var a : byte;
begin
   a := 7;
   if underline then a := $F;
   if bright then a := a or (1 shl 3);
   if blink then a := a or (1 shl 7);
   ChangeAttr(x,y,a);
end;



Procedure PutChar(x,y: Byte; ch: Char; fg, bg : byte);
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;
  mem[writeseg:(((y*80)+x) shl 1)]:=Byte(ch);
  mem[writeseg:(((y*80)+x) shl 1)+1]:=atr(fg,bg,false)
end;

Function GetChar(x,y: Byte): Char;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;
  GetChar:=Char(mem[writeseg:((y*80)+x) shl 1]);
end;

Function GetTextColor(x,y: Byte): Byte;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;

  GetTextColor:=mem[writeseg:(((y*80)+(x-1)) shl 1)+1] and $f;
end;

Function GetTextBackground(x,y: Byte): Byte;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;

  GetTextBackground:=mem[writeseg:(((y*80)+(x-1)) shl 1)+1] or $f;
end;

Procedure Cursor(onoff : boolean);
assembler;
asm
 mov ah,1

 cmp onoff,true
 je @on

 mov ch,32
 mov cl,7
 int 16
 jmp @exit


 @on:
  mov ch,6
  mov cl,7
  int 16
  jmp @exit

@EXIT:
end;


Procedure Fastwrite(x,y,fg, bg : byte; s : string);
var z : byte;
begin
 for z := 1 to length(s) do
 begin
  putchar(x+(z-1),y,s[z],fg,bg);
 end;
end;

Procedure CenteredText(y,c : byte; s : string);
begin
 fastwrite(40-(length(s) div 2),y,c,1,s);
end;

Procedure Box(xp,yp,xp1,yp1 : word; foreground, background : byte; slim : boolean);
var xc,yc : word;
begin

 if slim then
 begin

  for xc := xp to xp1 do
  begin
    putchar(xc,yp,'�',foreground,background);
    putchar(xc,yp1,'�',foreground,background);
  end;

  for yc := yp to yp1 do
  begin
   putchar(xp,yc,'�',foreground,background);
   putchar(xp1,yc,'�',foreground,background);
  end;

  putchar(xp,yp,'�',foreground,background);
  putchar(xp1,yp,'�',foreground,background);
  putchar(xp,yp1,'�',foreground,background);
  putchar(xp1,yp1,'�',foreground,background);

 end
 else
 begin

  for xc := xp to xp1 do
  begin
    putchar(xc,yp,'�',foreground,background);
    putchar(xc,yp1,'�',foreground,background);
  end;

  for yc := yp to yp1 do
  begin
   putchar(xp,yc,'�',foreground,background);
   putchar(xp1,yc,'�',foreground,background);
  end;

  putchar(xp,yp,'�',foreground,background);
  putchar(xp1,yp,'�',foreground,background);
  putchar(xp,yp1,'�',foreground,background);
  putchar(xp1,yp1,'�',foreground,background);
 end;
end;


Procedure Window(xp,yp,xp1,yp1 : word; c,b : byte; shadow : boolean);
var xc,yc : word;
begin
 for yc := yp to yp1 do
 begin
  for xc := xp to xp1 do
  begin
   putchar(xc,yc,' ',c,b);
   if (yc = yp) or (yc = yp1) then
   begin
    putchar(xc,yc,'�',c,b);
   end;
  end;

 if yc >= yp+1 then
 begin
  putchar(xp,yc,'�',c,b);
  putchar(xp1,yc,'�',c,b);
 end;

 end;
  putchar(xp,yp,'�',c,b);
  putchar(xp1,yp,'�',c,b);
  putchar(xp,yp1,'�',c,b);
  putchar(xp1,yp1,'�',c,b);

if shadow then
begin
 for yc := yp+1 to yp1+1 do
 begin
   putchar(xp1+1,yc,getchar(xp1+1,yc),8,0);
 end;
 for xc := xp+1 to xp1+1 do
 begin
   putchar(xc,yp1+1,getchar(xc,yp1+1),8,0);
 end;
end;
   cursor(false);
end;

Procedure SetBorder(Color : Word);
Assembler;
asm
 mov  ax, 0b00h
 mov  bx, Color
 int  10h
end;


Procedure Fill(c : char; attr : byte);
{Very fast screenfill}
assembler;
asm
   mov ax, writeseg;
   mov es, ax
   mov di, 4000;
   mov al, c
   mov ah, attr
   std
@Loop:
   stosw
   cmp di, 0
   jnz @Loop
   stosw
end;

Procedure ClrScr;
begin
 scrollup(0,0,0,79,24);
 gotoxy(1,1);
end;


Procedure Centeredline(y,c,b : byte; title : string);
var z,x : byte;
begin
  z := 1;
  for x := 1 to 80 do
  begin
    if (x >= (40-(length(title) div 2))) and (z <= length(title)) then
    begin
     putchar(x,y,title[z],c,b);
     inc(z);
    end
    else
    begin
      putchar(x,y,' ',c,b);
    end;
  end;
end;



Procedure InitMenuScreen(title : string);
var x,y,z : byte;
begin
  z := 0 or 7 and not (1 shl 7);   {Textfarbe 7, Hintergrund 0, blinken aus}
  Fill('�',z);
  Centeredline(1,14,1,title);
end;


Function Mouse_detected : boolean;
begin
  GetIntVec($33, mi);
  If (mi = NIL) then
    mouse_detected := False
  else
    if (Byte(mi^) = $CF) then mouse_detected := False
  else
    mouse_detected := True;
end;


Function Mouse_Init : Boolean;
assembler;
   asm
    xor ax,ax
    int $33
    cmp ax,0
    je  @failed
    mov mouse.nb,bl
    mov al,1
    jmp @quit
@failed:
    xor al,al
    mov mouse.nb,al
@quit:
end;

Procedure Mouse_SetHLimits(xmin, xmax : Word);
{ set horizontal limits }
assembler;
 asm
  cmp mouse_there,0
  je  @fail
  mov ax,7
  mov cx,xmin
  mov dx,xmax
  int $33
  @fail:
 end;

Procedure Mouse_SetVLimits(ymin, ymax : Word);
{ set vertical limits }
assembler;
 asm
  cmp mouse_there,0
  je  @fail
  mov ax,8
  mov cx,ymin
  mov dx,ymax
  int $33
  @fail:
 end;

Procedure Mouse_Show;
assembler;
 asm
  cmp mouse_there,0
  je  @fail
  mov ax,1
  int $33
  @fail:
 end;

Procedure Mouse_Hide;
assembler;
 asm
  cmp mouse_there,0
  je  @fail
  mov ax,2
  int $33
  @fail:
 end;

Procedure Mouse_Read;
assembler;
 asm
  cmp mouse_there,0
  je  @fail
  mov ax,3
  int $33
  mov mouse.x,cx
  mov mouse.y,dx
  mov mouse.b,bl
  @fail:
 end;

Procedure Mouse_SetPos(x, y : Byte);
assembler;
 asm
  cmp mouse_there,0
  je  @fail
  mov ax,4
  int $33
  mov mouse.x,cx
  mov mouse.y,dx
  @fail:
 end;


 Procedure GotoXY(x,y : byte);
 begin
   if x > 0 then x := x-1;
   if y > 0 then y := y-1;
   asm
    mov ah,2h
    mov bh,page
    mov dh,y
    mov dl,x
    int 10h
   end;
 end;

 function GetX : byte;
 var x : byte;
 begin
 asm
   mov ah,3
   mov bh,page
   int 10h
   mov x,dl
  end;
  GetX := x+1;
 end;

 function GetY : byte;
 var y : byte;
 begin
  asm
   mov ah,3
   mov bh,page
   int 10h
   mov y,dh
  end;
   GetY := Y+1;
 end;

 Procedure Textcolor(c : byte);
 begin
  tc := c;
 end;

 Procedure Textbackground(c : byte);
 begin
  tbc := c;
 end;

 Procedure Scrolldown(lines,x,y,x1,y1 : byte);
 var a : byte;
 begin
  a := atr(tc,tbc,false);
 asm
  mov ah,7
  mov al,lines
  mov bh,a
  mov cl,x
  mov ch,y
  mov dl,x1
  mov dh,y1
  int 10h
 end;
 end;

 Procedure Scrollup(lines,x,y,x1,y1 : byte);
 var a : byte;
 begin
  a := atr(tc,tbc,false);
 asm
  mov ah,6
  mov al,lines
  mov bh,a
  mov cl,x
  mov ch,y
  mov dl,x1
  mov dh,y1
  int 10h
 end;
 end;

 Procedure Write(s : string);
 var cnt,x,y : word;
 begin
  x := GetX;
  y := GetY;

  for cnt := 1 to length(s) do
  begin
   putchar(x,y,s[cnt],tc,tbc);

   inc(x);
   if x = 81 then
   begin
    x := 1;
    if y = 25 then
    begin
     scrollup(1,0,0,79,24);
    end
    else
    begin
      inc(y);
    end;
   end;

  end;
  gotoxy(x,y);
end;


 Procedure Writeln(s : string);
 var cnt,y : byte;
 begin
  write(s);
  y := getY;
  if y = 25 then
  begin
   scrollup(1,0,0,79,24);
   gotoxy(1,25);
  end
  else
  begin
   gotoxy(1,y+1);
  end;
  end;

 Procedure SetWritePage(p : byte);
 begin
  page := p;
 end;

 Procedure SetViewPage(p : byte);
 assembler;
 asm
  mov ah,5;
  mov al,p
  int 10h
 end;

 Procedure Writeto(p : pointer);
 begin
  writeseg := seg(p^);
 end;

 Procedure ViewBuffer(p : pointer);
 begin
  move(p^,ptr(viewseg,0)^,4000);
 end;

 Procedure ShadowScreen;
 var atr : byte;
     z   : word;
 begin
  atr := 0;
  atr := atr shl 4;
  atr := atr or 8;
  atr := atr and not (1 shl 7);   {Blinken aus}

  z := 1;
  repeat;
   mem[writeseg:z]:=atr;
   inc(z,2);
  until (z >= 4000);
 end;


begin
 mouse_there := mouse_detected;
 tc := 7;
 tbc := 0;

 VidSeg := Detect_VidSeg;
 viewseg := VidSeg;
 writeseg := viewseg;

end.

