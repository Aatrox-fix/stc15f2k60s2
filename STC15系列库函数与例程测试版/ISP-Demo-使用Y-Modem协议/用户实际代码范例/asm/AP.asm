;/*------------------------------------------------------------------*/
;/* --- STC MCU International Limited -------------------------------*/
;/* --- STC IAP 系列单片机实现用户ISP 演示程序 ----------------------*/
;/* --- Mobile: (86)13922805190 -------------------------------------*/
;/* --- Fax: 86-755-82944243 ----------------------------------------*/
;/* --- Tel: 86-755-82948412 ----------------------------------------*/
;/* --- Web: www.STCMCU.com -----------------------------------------*/
;/* 如果要在程序中使用或者在文章中引用该程序,请在程序中或文章中注明  */
;/* 使用了宏晶科技的资料或程序                                       */
;/*------------------------------------------------------------------*/

;------------------------------------------------
;/*定义常数*/

UARTBAUD	EQU     250                 ;定义串口波特率 (256-22118400/32/115200)	要跟IAPISP波特率相同

;------------------------------------------------
;/*定义特殊功能寄存器*/

AUXR        data    08EH                ;附件功能控制寄存器
ISP_CONTR   data    0C7H
PCON2       data    097H   ;for IAP15F2K61S2
P_SW1       data    0A2H   ;for IAP15F2K61S2

;------------------------------------------------
;/*定义用户变量*/

HandCnt       DATA    60H                 ;接收7F的计数器,当连续接收到16次7F后进入ISP下载模式

;------------------------------------------------
;/*中断向量表*/

        ORG     0000H
        LJMP    START                   ;系统复位入口

        ORG     0023H
        LJMP    F_UART_ISR                ;串口中断入口

;------------------------------------------------
;/*串口中断服务程序*/

F_UART_ISR:
        PUSH    ACC
        PUSH    PSW
        JNB     TI,L_CheckRx            ;检测发送中断
        CLR     TI                      ;清除标志
L_CheckRx:
        JNB     RI,L_UARTISR_EXIT         ;检测接收中断
        CLR     RI                      ;清除标志
        MOV     A,SBUF
        CJNE    A,#'d',L_IsNotHand
        INC     HandCnt
        MOV     A,HandCnt
        CJNE    A,#16,L_UARTISR_EXIT
        MOV		ISP_CONTR,#20H          ;复位到AP入口
L_IsNotHand:
        MOV     HandCnt,#0
L_UARTISR_EXIT:
        POP     PSW
        POP     ACC
        RETI

;------------------------------------------------
;/*主程序入口*/

START:
        MOV     R0,#7FH                 ;清RAM
        CLR     A
        MOV     @R0,A
        DJNZ    R0,$-1
        MOV     SP,#7FH                 ;初始化SP

        MOV     SCON,#50H               ;设置串口模式(8为可变,无校验位)
        MOV     AUXR,#40H               ;Timer1工作于1T模式
        MOV	TMOD,#0x20
;对于IAP15F2K61S2, 增加这两句,串口1可以切换P30,P31
;   	ANL     P_SW1,#NOT 0xc0         ;S1_USE_P30P31();
;	ANL     PCON2,#NOT (1 SHL 4)    ;S1_TXD_RXD_OPEN();

	MOV     TH1,#UARTBAUD           ;设置重载值
        SETB	TR1
	SETB    ES                      ;使能串口中断
        SETB    EA                      ;开中断总开关

MAIN:
        INC     P1
        SJMP    MAIN

;------------------------------------------------

        END
