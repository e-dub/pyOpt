      SUBROUTINE PSQPW(NF,NC,X,IX,XL,XU,CF,IC,CL,CU,CZ,XMAX,TOLX,
     +     TOLC,TOLG,RPF,CMAX,F,MIT,MFV,MET,MEC,IPRNT,IOUT,IFILE,
     +     ITERM,NRES_,NDEC_,NREM_,NADD_,NIT_,NFV_,NFG_,NFH_,
     +     POBJ,PDOBJ,PCON,PDCON)
C
C***********************************************************************
C
C  WRAPPING SUBROUTINE FOR PSQP
C
C  PARAMETERS :
C    NF        NUMBER OF VARIABLES.
C    NC        NUMBER OF LINEAR CONSTRAINTS.
C    X(NF)     VECTOR OF VARIABLES.
C    IX(NF)    VECTOR CONTAINING TYPES OF BOUNDS. 
C               IX(I)=0-VARIABLE X(I) IS UNBOUNDED. 
C               IX(I)=1-LOVER BOUND XL(I).LE.X(I).
C               IX(I)=2-UPPER BOUND X(I).LE.XU(I). 
C               IX(I)=3-TWO SIDE BOUND XL(I).LE.X(I).LE.XU(I). 
C               IX(I)=5-VARIABLE X(I) IS FIXED.
C    XL(NF)    VECTOR CONTAINING LOWER BOUNDS FOR VARIABLES.
C    XU(NF)    VECTOR CONTAINING UPPER BOUNDS FOR VARIABLES.
C    CF(NC+1)  VECTOR CONTAINING VALUES OF THE CONSTRAINT FUNCTIONS.
C    IC(NC)    VECTOR CONTAINING TYPES OF CONSTRAINTS.
C               IC(KC)=0-CONSTRAINT CF(KC) IS NOT USED. 
C               IC(KC)=1-LOWER CONSTRAINT CL(KC).LE.CF(KC). 
C               IC(KC)=2-UPPER CONSTRAINT CF(KC).LE.CU(KC). 
C               IC(KC)=3-TWO SIDE CONSTRAINT CL(KC).LE.CF(KC).LE.CU(KC). 
C               IC(KC)=5-EQUALITY CONSTRAINT CF(KC).EQ.CL(KC).
C    CL(NC)    VECTOR CONTAINING LOWER BOUNDS FOR CONSTRAINT FUNCTIONS.
C    CU(NC)    VECTOR CONTAINING UPPER BOUNDS FOR CONSTRAINT FUNCTIONS.
C    CZ(NF)    VECTOR OF LAGRANGE MULTIPLIERS.
C    XMAX      MAXIMUM STEPSIZE.
C    TOLX      TOLERANCE FOR CHANGE OF VARIABLES.
C    TOLC      TOLERANCE FOR CONSTRAINT VIOLATIONS.
C    TOLG      TOLERANCE FOR THE GRADIENT OF THE LAGRANGIAN FUNCTION.
C    RPF       PENALTY COEFFICIENT.
C    CMAX      MAXIMUM CONSTRAINT VIOLATION.
C    GMAX      MAXIMUM PARTIAL DERIVATIVE OF THE LAGRANGIAN FUNCTION.
C    F         VALUE OF THE OBJECTIVE FUNCTION.
C    MIT       MAXIMUM NUMBER OF ITERATIONS.
C    MFV       MAXIMUN NUMBER OF FUNCTION EVALUATIONS.
C    MET       VARIABLE METRIC UPDATE USED. 
C               MET=1-THE BFGS UPDATE. 
C               MET=2-THE HOSHINO UPDATE.
C    MEC       CORRECTION IF THE NEGATIVE CURVATURE OCCURS. 
C               MEC=1-CORRECTION SUPPRESSED. 
C               MEC=2-POWELL'S CORRECTION.
C    IPRNT     PRINT SPECIFICATION. 
C               IPRNT=0-NO PRINT.
C               ABS(IPRNT)=1-PRINT OF FINAL RESULTS.
C               ABS(IPRNT)=2-PRINT OF FINAL RESULTS AND ITERATIONS.
C               IPRNT>0-BASIC FINAL RESULTS. 
C               IPRNT<0-EXTENDED FINAL RESULTS.
C    IOUT      PRINT OUTPUT UNIT NUMBER.
C    IFILE     PRINT FILENAME.
C    ITERM     VARIABLE THAT INDICATES THE CAUSE OF TERMINATION.
C               ITERM=1-IF ABS(X-XO) WAS LESS THAN OR EQUAL TO TOLX IN MTESX (USUALLY TWO) SUBSEQUEBT ITERATIONS.
C               ITERM=2-IF ABS(F-FO) WAS LESS THAN OR EQUAL TO TOLF IN MTESF (USUALLY TWO) SUBSEQUEBT ITERATIONS.
C               ITERM=3-IF F IS LESS THAN OR EQUAL TO TOLB.
C               ITERM=4-IF GMAX IS LESS THAN OR EQUAL TO TOLG.
C               ITERM=11-IF NIT EXCEEDED MIT. 
C               ITERM=12-IF NFV EXCEEDED MFV.
C               ITERM=13-IF NFG EXCEEDED MFG. 
C               ITERM<0-IF THE METHOD FAILED.
C               IF ITERM=-6, THEN THE TERMINATION CRITERION HAS NOT BEEN SATISFIED, BUT THE POINT OBTAINED IF USUALLY ACCEPTABLE.
C
C  VARIABLES IN COMMON /STAT/ (STATISTICS) :
C    NRES       NUMBER OF RESTARTS.
C    NDEC       NUMBER OF MATRIX DECOMPOSITION.
C    NREM       NUMBER OF CONSTRAINT DELETIONS.
C    NADD       NUMBER OF CONSTRAINT ADDITIONS.
C    NIT        NUMBER OF ITERATIONS.
C    NFV        NUMBER OF FUNCTION EVALUATIONS.
C    NFG        NUMBER OF GRADIENT EVALUATIONS.
C    NFH        NUMBER OF HESSIAN EVALUATIONS.
C
C  SUBPROGRAMS USED :
C  S   PSQP  RECURSIVE QUADRATIC PROGRAMMING METHOD WITH THE BFGS
C         VARIABLE METRIC UPDATE.
C
C  EXTERNAL SUBROUTINES :
C    POBJ  COMPUTATION OF THE VALUE OF THE OBJECTIVE FUNCTION.
C         CALLING SEQUENCE: CALL OBJ(NF,X,FF) WHERE NF IS THE NUMBER
C         OF VARIABLES, X(NF) IS A VECTOR OF VARIABLES AND FF IS THE
C         VALUE OF THE OBJECTIVE FUNCTION.
C    PDOBJ  COMPUTATION OF THE GRADIENT OF THE OBJECTIVE FUNCTION.
C         CALLING SEQUENCE: CALL DOBJ(NF,X,GF) WHERE NF IS THE NUMBER
C         OF VARIABLES, X(NF) IS A VECTOR OF VARIABLES AND GC(NF) IS
C         THE GRADIENT OF THE OBJECTIVE FUNCTION.
C    PCON  COMPUTATION OF THE VALUE OF THE CONSTRAINT FUNCTION.
C         CALLING SEQUENCE: CALL CON(NF,KC,X,FC) WHERE NF IS THE
C         NUMBER OF VARIABLES, KC IS THE INDEX OF THE CONSTRAINT
C         FUNCTION, X(NF) IS A VECTOR OF VARIABLES AND FC IS THE
C         VALUE OF THE CONSTRAINT FUNCTION.
C    PDCON  COMPUTATION OF THE GRADIENT OF THE CONSTRAINT FUNCTION.
C         CALLING SEQUENCE: CALL DCON(NF,KC,X,GC) WHERE NF IS THE
C         NUMBER OF VARIABLES, KC IS THE INDEX OF THE CONSTRAINT
C         FUNCTION, X(NF) IS A VECTOR OF VARIABLES AND GC(NF) IS THE
C         GRADIENT OF THE CONSTRAINT FUNCTION.
C
C***********************************************************************
C      
      DOUBLE PRECISION XMAX,TOLX,TOLC,TOLG,RPF,CMAX,GMAX,F
      INTEGER          NF,NB,NC,MIT,MFV,MET,MEC,IPRNT,IOUT,ITERM
      DOUBLE PRECISION X(NF),XL(NF),XU(NF),CF(NC+1),CL(NC),CU(NC),
     +                 CG(NF*NC),CFO(NC),CFD(NC),GC(NF),
     +                 CR(NF*(NF+1)/2),CZ(NF),CP(NF),GF(NF),G(NF),
     +                 H(NF*(NF+1)/2),S(NF),XO(NF),GO(NF)
      INTEGER          IX(NF),IC(NC),ICA(NF)
      INTEGER          NRES_,NDEC_,NREM_,NADD_,NIT_,NFV_,NFG_,NFH_
      INTEGER          NRES,NDEC,NREM,NADD,NIT,NFV,NFG,NFH
      
      CHARACTER*(*)    IFILE
      
      EXTERNAL         POBJ,PDOBJ,PCON,PDCON
      
      COMMON           /STAT/NRES,NDEC,NREM,NADD,NIT,NFV,NFG,NFH
C     
C  STAT COUNTERS
C
      NRES=NRES_
      NDEC=NDEC_
      NREM=NREM_
      NADD=NADD_
      NIT=NIT_
      NFV=NFV_
      NFG=NFG_
      NFH=NFH_
C 
C  OPEN WRITE FILE
C     
      IF (IPRNT.EQ.0) GO TO 10
      OPEN(UNIT=IOUT,FILE=IFILE,STATUS='UNKNOWN')
10    CONTINUE
C 
C  CALL PSQP
C 
      CALL PSQP(NF,NB,NC,X,IX,XL,XU,CF,IC,CL,CU,CG,CFO,CFD,GC,
     +     ICA,CR,CZ,CP,GF,G,H,S,XO,GO,XMAX,TOLX,TOLC,TOLG,
     +     RPF,CMAX,GMAX,F,MIT,MFV,MET,MEC,IPRNT,IOUT,ITERM,
     +     POBJ,PDOBJ,PCON,PDCON)
C
C  OUTPUT HANDLING
C
      NRES_=NRES
      NDEC_=NDEC
      NREM_=NREM
      NADD_=NADD
      NIT_=NIT
      NFV_=NFV
      NFG_=NFG
      NFH_=NFH
C
      RETURN
      END