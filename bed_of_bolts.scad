/**
Run get_deps.sh to clone dependencies into a linked folder in your home directory.
*/

use <deps.link/BOSL/nema_steppers.scad>
use <deps.link/BOSL/joiners.scad>
use <deps.link/BOSL/shapes.scad>
use <deps.link/BOSL/acme_screws.scad>
use <deps.link/BOSL/metric_screws.scad>
use <deps.link/erhannisScad/misc.scad>
use <deps.link/erhannisScad/auto_lid.scad>
use <deps.link/scadFluidics/common.scad>
use <deps.link/quickfitPlate/blank_plate.scad>
use <deps.link/getriebe/Getriebe.scad>
use <deps.link/gearbox/gearbox.scad>
use <parametricPulley.scad>

$FOREVER = 1000;
DUMMY = false;
$fn = DUMMY ? 10 : 60;
MKFN = $fn;

//RAINY Maybe a SCALE variable?

SCALE = 1.0;
SLOP = 0.4;
SLOP2 = SLOP*2;
BOLT_OD = 10*SCALE;
NON_LOAD_T = 1; //THINK Maybe scale?

TRANSFER_WALL = 2*SCALE;
TRANSFER_TEETH = ceil(15*SCALE);
INTERLOCK_SZ = 10*SCALE;
TRANSFER_SZ = 2*INTERLOCK_SZ;
PFEILRAD_DIMS = pfeilrad_dims(modul=1, zahnzahl=TRANSFER_TEETH, breite=TRANSFER_SZ, bohrung=BOLT_OD+SLOP2, eingriffswinkel=20, schraegungswinkel=0, optimiert=false);
PFEILRAD_OD = PFEILRAD_DIMS[0];
PFEILRAD_ID = PFEILRAD_DIMS[2];
HOHLRAD_OD = 2*TRANSFER_WALL + PFEILRAD_OD;

BOLT_RETAINER_T = DUMMY ? -SLOP2 : 2*SCALE; //THINK Not sure abt scale
BOLT_RETAINER_L = INTERLOCK_SZ;
BOLT_RETAINER_D = BOLT_OD*0.2;

DRIVE_SLEEVE_A_TEETH = ceil(47*SCALE);
DRIVE_SLEEVE_A_OD = tooth_spacing(2,0.254,DRIVE_SLEEVE_A_TEETH);
DRIVE_SLEEVE_A_OD2 = DRIVE_SLEEVE_A_OD+(4/3); //RAINY Should probably be calculated in parametricPulley.scad, not hardcoded
DRIVE_SLEEVE_A_SZ = pulley_height();
DRIVE_SLEEVE_A_RETAINING_GROOVE_SZ = 2.5;
DRIVE_SLEEVE_A_RETAINING_GROOVE_T = 2.5;
DRIVE_SLEEVE_A_RRING_CENTER = 0.5*(DRIVE_SLEEVE_A_OD+PFEILRAD_OD);
DRIVE_SLEEVE_A_FOOT_SZ = (DRIVE_SLEEVE_A_OD2-(PFEILRAD_OD+SLOP2))/2;

DRIVE_SLEEVE_B_FLANGE_D = HOHLRAD_OD+4*SCALE;
DRIVE_SLEEVE_B_FLANGE_T = 6*SCALE;
DRIVE_SLEEVE_B_FLANGE_SOCKET_T = DRIVE_SLEEVE_B_FLANGE_T;

module TransferStirnrad(sz=TRANSFER_SZ-SLOP2,bore=BOLT_OD+SLOP2,chamfer1=true,chamfer2=true,slopwall=0) {
  difference() {
    stirnrad(modul=1, zahnzahl=TRANSFER_TEETH, breite=sz, bohrung=bore, eingriffswinkel=20, schraegungswinkel=0, optimiert=false);
    if (chamfer1) {
      TransferChamfersInner();
    }
    if (chamfer2) {
      tz(sz) TransferChamfersInner();
    }
  }
  if (slopwall > 0) {
    tz(sz) tube(od=PFEILRAD_ID, id=bore, h=slopwall);
  }
}

module TransferHohlrad(sz=TRANSFER_SZ-SLOP2,chamfer1=true,chamfer2=true,slopwall=0) {
  difference() {
    // Bulk
    cylinder(d=HOHLRAD_OD,h=sz);
    // Gear pattern
    minkowski() {
      stirnrad(modul=1, zahnzahl=TRANSFER_TEETH, breite=sz, bohrung=BOLT_OD+SLOP2, eingriffswinkel=20, schraegungswinkel=0, optimiert=false);
      cylinder(d=SLOP2,h=0.01,center=true,$fn=MKFN);
    }
    // Central hole
    cylinder(d=BOLT_OD+SLOP2,h=$FOREVER,center=true);
    // Chamfers
    if (chamfer1) {
      TransferChamfersOuter();
    }
    if (chamfer2) {
      tz(sz) TransferChamfersOuter();
    }
  }
  if (slopwall > 0) {
    tz(sz) tube(od=HOHLRAD_OD, id=PFEILRAD_OD+SLOP2, h=slopwall);
  }
}

module TransferSleeve() {
  //THINK This MIGHT be better for stability, but also uses space
  //tz(2*INTERLOCK_SZ) tube(od=PFEILRAD_ID, id=BOLT_OD+SLOP2, h=INTERLOCK_SZ);

  TransferStirnrad();
  
  tz(-1*INTERLOCK_SZ) tube(od=PFEILRAD_ID, id=BOLT_OD+SLOP2, h=INTERLOCK_SZ);
  tz(-2*INTERLOCK_SZ) tube(od1=HOHLRAD_OD, od2=PFEILRAD_ID, id1=PFEILRAD_OD+SLOP2, id2=BOLT_OD+SLOP2, h=INTERLOCK_SZ);
  //tz(-2*INTERLOCK_SZ) tube(od=HOHLRAD_OD, id=PFEILRAD_OD+SLOP2, h=INTERLOCK_SZ/2);
  
  tz(-4*INTERLOCK_SZ) TransferHohlrad(slopwall=SLOP2);
  
  //DUMMY Outer clutch rings
}

module BoltCore(negative=false) {
  if (negative) {
    threaded_rod(d=BOLT_OD+SLOP2, pitch = DUMMY ? 8 : 2);
  } else {
    threaded_rod(d=BOLT_OD, pitch = DUMMY ? 8 : 2);
  }
}

module Bolt() {
  //RAINY I like the look of the trapezoidal threaded rod, but it probably sucks to print, so normal threaded rod it is, for now.
  difference() {
    BoltCore();
    cmy() ty((BOLT_OD/2)-BOLT_RETAINER_D) ty(-SLOP) translate([-(BOLT_RETAINER_T+SLOP2)/2,0,-$FOREVER/2]) cube([BOLT_RETAINER_T+SLOP2, $FOREVER, $FOREVER]);
  }
}

module Housing() {
  HOUSING_OD = HOHLRAD_OD+20;
  bottom = 4*INTERLOCK_SZ+DRIVE_SLEEVE_B_FLANGE_T+DRIVE_SLEEVE_B_FLANGE_SOCKET_T+SLOP;
  
  // Drive Sleeve A retaining ring
  tz(DRIVE_SLEEVE_A_SZ-DRIVE_SLEEVE_A_RETAINING_GROOVE_SZ) rotate_extrude() {
    x = DRIVE_SLEEVE_A_RETAINING_GROOVE_T/2;
    y = DRIVE_SLEEVE_A_RETAINING_GROOVE_SZ/2;
    tx(DRIVE_SLEEVE_A_RRING_CENTER/2) polygon([
      [-x,2*y],
      //[-x/2,y], // Wall groove
      [-x,0],
      [0,x], // Center groove
      [x,0],
      //[x/2,y], // Wall groove
      [x,2*y],
      [x,20],
      [-x,20],
    ]);
  }

  difference() {
    union() {
      tz(3*INTERLOCK_SZ) difference() {
        tube(id=BOLT_OD+SLOP2,od=HOUSING_OD,h=INTERLOCK_SZ);
        cmy() ty((BOLT_OD/2)-BOLT_RETAINER_D) ty(-SLOP) translate([-(BOLT_RETAINER_T+SLOP2)/2,0,-$FOREVER/2]) cube([BOLT_RETAINER_T+SLOP2, BOLT_RETAINER_D*2+SLOP2, $FOREVER]);
      }
      
      tz(2*INTERLOCK_SZ) {
        TransferHohlrad(sz=INTERLOCK_SZ,chamfer2=false);
        tube(id=HOHLRAD_OD,od=HOUSING_OD,h=INTERLOCK_SZ);
      }
      tz(DRIVE_SLEEVE_A_SZ+SLOP) tube(id=PFEILRAD_OD+SLOP2, od=HOUSING_OD, h=2*INTERLOCK_SZ-DRIVE_SLEEVE_A_SZ-SLOP);
      
      // Drive Sleeve A support ledge
      tz(-DRIVE_SLEEVE_A_FOOT_SZ-SLOP) mz() tube(od=MAIN_CHAMBER_ID, id1=DRIVE_SLEEVE_A_OD2-SLOP2*2, id2=MAIN_CHAMBER_ID, h=(MAIN_CHAMBER_ID-(DRIVE_SLEEVE_A_OD2-SLOP2*2))/2);

      MAIN_CHAMBER_ID = DRIVE_SLEEVE_A_OD+3;
            
      tube(id=MAIN_CHAMBER_ID, od=HOUSING_OD, h=DRIVE_SLEEVE_A_SZ+SLOP);
      
      // Tall wall
      mz() tube(id=MAIN_CHAMBER_ID, od=HOUSING_OD, h=bottom);
      
      // Drive flange socket
      //DUMMY Will need more space for transfer sleeve rings
      tz(-bottom+DRIVE_SLEEVE_B_FLANGE_SOCKET_T+SLOP+DRIVE_SLEEVE_B_FLANGE_T+SLOP) tube(id=HOHLRAD_OD+SLOP2, od=HOUSING_OD, h=DRIVE_SLEEVE_B_FLANGE_SOCKET_T);
      tz(-bottom+DRIVE_SLEEVE_B_FLANGE_SOCKET_T) tube(id=DRIVE_SLEEVE_B_FLANGE_D+SLOP2*2, od=HOUSING_OD, h=SLOP+DRIVE_SLEEVE_B_FLANGE_T+SLOP);
      tz(-bottom) tube(id=BOLT_OD+SLOP2, od=HOUSING_OD, h=DRIVE_SLEEVE_B_FLANGE_SOCKET_T);
    }
    
    // Slots
    slot_adjust = 1;
    ctranslate([0,0,-2.5*INTERLOCK_SZ]) tz(DRIVE_SLEEVE_A_SZ/2) crotate([0,0,90]) cmx() tx(DRIVE_SLEEVE_A_OD/2+1-slot_adjust/2) house([4+slot_adjust,100,10]);
    tz(-bottom+5+DRIVE_SLEEVE_B_FLANGE_SOCKET_T) crotate([0,0,90]) house([10,100,10]);
  }
}

module ClutchGear() {
}

module DriveSleeveA() {
  difference() {
    union() {
      TransferHohlrad(sz=DRIVE_SLEEVE_A_SZ);
      
      // GT2 timing belt teeth
      difference() {
        pulley("GT2 2mm" , DRIVE_SLEEVE_A_OD, 0.764, 1.494, DRIVE_SLEEVE_A_TEETH, cutouts=false);
        cylinder(d=PFEILRAD_OD+SLOP2,h=$FOREVER,center=true);
      }
      
      // Support foot
      mz() tube(od=DRIVE_SLEEVE_A_OD2, id1=PFEILRAD_OD+SLOP2, id2=DRIVE_SLEEVE_A_OD2, h=DRIVE_SLEEVE_A_FOOT_SZ);
    }
    
    // Retaining ring
    rring_center = DRIVE_SLEEVE_A_RRING_CENTER;
    rrxslop = SLOP*3;
    tz(pulley_height()) tube(id=rring_center-DRIVE_SLEEVE_A_RETAINING_GROOVE_T-rrxslop, od=rring_center+DRIVE_SLEEVE_A_RETAINING_GROOVE_T+rrxslop, h=2*(DRIVE_SLEEVE_A_RETAINING_GROOVE_SZ+SLOP), center=true);
  }
}


module DriveSleeveB() {
  difference() {
    union() {
      mz() cylinder(d=DRIVE_SLEEVE_B_FLANGE_D,h=DRIVE_SLEEVE_B_FLANGE_T);
      TransferStirnrad(bore=0,chamfer1=false);
    }
    
    // Bolt threads
    BoltCore(negative=true);
    
    // Chamfer
    tz(-DRIVE_SLEEVE_B_FLANGE_T) cylinder(d1=BOLT_OD+SLOP2*2, d2=0, h=(BOLT_OD+SLOP2*2)/2);
    
    // VSlot
    vsx = 2;
    vsy = $FOREVER;
    vsz = 2;
    vsd = 3;
    tz(-DRIVE_SLEEVE_B_FLANGE_T/2) crotate([0,0,90]) cmy() ty(DRIVE_SLEEVE_B_FLANGE_D/2 - vsd) ty(vsy/2) vslot([vsx,vsy,vsz]);
    
    // Underside v-grooves
    tz(-DRIVE_SLEEVE_B_FLANGE_T) rotate_extrude() {
//      ctranslate([
//        [DRIVE_SLEEVE_B_FLANGE_D/2,0],
//      ]) rz(-45) square(center=true);
      rz(-45) union() {
        d = 2;
        for (i=[sqrt(0.5)*DRIVE_SLEEVE_B_FLANGE_D/2:-d:sqrt(0.5)*BOLT_OD/2]) {
          translate([i,i]) square(d, center=true);
        }
      }
    }
  }
}

// The retainer itself doesn't apply force; it just positions the key fins for the bolt and the housing.
module BoltRetainer() {
  // Flange
  difference() {
    cylinder(d=BOLT_OD*1.5,h=NON_LOAD_T);
    cylinder(d=BOLT_OD+SLOP2,h=$FOREVER,center=true);
  }
  
  // Fins
  cmy() mz() ty((BOLT_OD/2)-BOLT_RETAINER_D) tx(-BOLT_RETAINER_T/2) tz(-NON_LOAD_T) cube([BOLT_RETAINER_T, BOLT_RETAINER_D*2, BOLT_RETAINER_L+NON_LOAD_T]);
}

module Assembly(engaged=true) {
  Housing();
  tz(-2) Bolt();
  DriveSleeveA();
  tz(-4*INTERLOCK_SZ) DriveSleeveB();
  tz(engaged ? SLOP : INTERLOCK_SZ) TransferSleeve();
  ClutchGear();
  //tz(4*INTERLOCK_SZ) BoltRetainer(); //CHECK Maybe top AND bottom?
}



//BoltRetainer();
difference() {
  Assembly(true);
  OXpYm();
  //OZp([0,0,35]);
}

// schnecke(modul=1, gangzahl=2, laenge=15, bohrung=4, eingriffswinkel=20, steigungswinkel=10, zusammen_gebaut=true);

// schneckenradsatz(modul=1, zahnzahl=30, gangzahl=2, breite=8, laenge=20, bohrung_schnecke=4, bohrung_rad=4, eingriffswinkel=20, steigungswinkel=10, optimiert=true, zusammen_gebaut=true);

//DUMMY This isn't handling slop correctly
module TransferChamfersOuter() {
  minkowski() {
    stirnrad(modul=1, zahnzahl=TRANSFER_TEETH, breite=0.01, bohrung=BOLT_OD+SLOP2, eingriffswinkel=20, schraegungswinkel=0, optimiert=false);
    cmz() cylinder(d1=1+SLOP2,d2=0,h=1+SLOP2,$fn=MKFN);
  }
}

module TransferChamfersInner() {
  minkowski() {
    hohlrad(modul=1, zahnzahl=TRANSFER_TEETH, breite=0.01, randbreite=3, eingriffswinkel=20, schraegungswinkel=0);
    cmz() cylinder(d1=1,d2=0,h=1,$fn=MKFN);
  }
}

/*
Notes from test print:
*Transfer sleeve was great.
*DriveSleeveB was quite difficult to free, and quite sticky after.
  *groove bottom
  *twist handholds
  *smaller groove
*Bolt was welded in by the threads.
  *Print separately, I guess
  *Also, chamfer bottom of DriveSleeveB
*DriveSleeveA was stuck REAL good, and the groove was VERY sticky even after freeing
  *Extend bottom to V point on wall?
  *Hollow out groove ring to upside-down V?
*/


