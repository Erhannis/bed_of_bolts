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
$fn = DUMMY ? 20 : 60;
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

HOUSING_OD = 50-SLOP;
echo("HOUSING_OD", HOUSING_OD);

DRIVE_SLEEVE_A_TEETH = ceil(47*SCALE);
DRIVE_SLEEVE_A_OD = tooth_spacing(2,0.254,DRIVE_SLEEVE_A_TEETH);
DRIVE_SLEEVE_A_OD2 = DRIVE_SLEEVE_A_OD+(4/3); //RAINY Should probably be calculated in parametricPulley.scad, not hardcoded
DRIVE_SLEEVE_A_SZ = pulley_height();
DRIVE_SLEEVE_A_RETAINING_GROOVE_SZ = 2.5;
DRIVE_SLEEVE_A_RETAINING_GROOVE_T = 1.5;
DRIVE_SLEEVE_A_RRING_CENTER = 0.5*(DRIVE_SLEEVE_A_OD+PFEILRAD_OD);
DRIVE_SLEEVE_A_FOOT_SZ = (DRIVE_SLEEVE_A_OD2-(PFEILRAD_OD+SLOP2))/2;

DRIVE_SLEEVE_B_FLANGE_D = HOHLRAD_OD+4*SCALE;
DRIVE_SLEEVE_B_FLANGE_T = 6*SCALE;
DRIVE_SLEEVE_B_FLANGE_SOCKET_T = DRIVE_SLEEVE_B_FLANGE_T;

BOLT_RETAINER_T = DUMMY ? -SLOP2 : 2*SCALE; //THINK Not sure abt scale
BOLT_RETAINER_TOP_L = INTERLOCK_SZ;
BOLT_RETAINER_BOT_L = DRIVE_SLEEVE_B_FLANGE_T;
BOLT_RETAINER_D = BOLT_OD*0.2;

RIB_PITCH = 2;
RIB_ANGLE = 45;
RIB_DEPTH = 0.5*RIB_PITCH*tan(90-RIB_ANGLE);
CLUTCH_INTERMEDIARY_T = 4;
CLUTCH_INTERMEDIARY_STOPS_T = 1.5;
CLUTCH_INTERMEDIARY_RIB_ID = HOHLRAD_OD+2*RIB_DEPTH+2*SLOP;
CLUTCH_SLEEVE_THREAD_ID = CLUTCH_INTERMEDIARY_RIB_ID+2*CLUTCH_INTERMEDIARY_T+2.5+SLOP2; // Like, in the valley
CLUTCH_SLEEVE_T = 2;
CLUTCH_SLEEVE_SZ = 2*INTERLOCK_SZ;
CLUTCH_SLEEVE_OD = CLUTCH_SLEEVE_THREAD_ID+CLUTCH_SLEEVE_T;
CLUTCH_SLEEVE_GT_TEETH = ceil(62*SCALE);
CLUTCH_SLEEVE_GT_OD = tooth_spacing(2,0.254,CLUTCH_SLEEVE_GT_TEETH);
CLUTCH_SLEEVE_GT_OD2 = CLUTCH_SLEEVE_GT_OD+(4/3); //RAINY Should probably be calculated in parametricPulley.scad, not hardcoded

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

  // Upper stirnrad
  TransferStirnrad();
  
  // Straight tube
  tz(-1*INTERLOCK_SZ) tube(od=PFEILRAD_ID, id=BOLT_OD+SLOP2, h=INTERLOCK_SZ);
  
  // Taper
  tz(-2*INTERLOCK_SZ) tube(od1=HOHLRAD_OD, od2=PFEILRAD_ID, id1=PFEILRAD_OD+SLOP2, id2=BOLT_OD+SLOP2, h=INTERLOCK_SZ);
  
  // Lower hohlrad
  tz(-4*INTERLOCK_SZ) TransferHohlrad(slopwall=SLOP2);
  
  // Outer clutch rings
  tz(-4*INTERLOCK_SZ+DRIVE_SLEEVE_B_FLANGE_T+SLOP) ribbing(angle=RIB_ANGLE,pitch=RIB_PITCH,id=HOHLRAD_OD,h=INTERLOCK_SZ);
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

HOUSING_BOTTOM = 4*INTERLOCK_SZ+DRIVE_SLEEVE_B_FLANGE_T+DRIVE_SLEEVE_B_FLANGE_SOCKET_T+SLOP;
module Housing() {
  bottom = HOUSING_BOTTOM;
  
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
      [x,3*y],
      [-x,3*y],
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
      tz(-DRIVE_SLEEVE_A_FOOT_SZ-SLOP) mz() tube(od=MAIN_CHAMBER_ID, id1=DRIVE_SLEEVE_A_OD2-SLOP2*3, id2=MAIN_CHAMBER_ID, h=(MAIN_CHAMBER_ID-(DRIVE_SLEEVE_A_OD2-SLOP2*3))/2);

      MAIN_CHAMBER_ID = DRIVE_SLEEVE_A_OD+3;
            
      tube(id=MAIN_CHAMBER_ID, od=HOUSING_OD, h=DRIVE_SLEEVE_A_SZ+SLOP);
      
      // Tall wall
      mz() tube(id=MAIN_CHAMBER_ID, od=HOUSING_OD, h=bottom);
        
      // Drive flange socket
      //// Upper slab
      tz(-bottom+DRIVE_SLEEVE_B_FLANGE_SOCKET_T+SLOP+DRIVE_SLEEVE_B_FLANGE_T+SLOP) tube(id=HOHLRAD_OD+SLOP2, od=HOUSING_OD, h=DRIVE_SLEEVE_B_FLANGE_SOCKET_T);
      //// Middle, outer ring
      tz(-bottom+DRIVE_SLEEVE_B_FLANGE_SOCKET_T) tube(id=DRIVE_SLEEVE_B_FLANGE_D+SLOP2*2, od=HOUSING_OD, h=SLOP+DRIVE_SLEEVE_B_FLANGE_T+SLOP);
      //// Bottom slab
      difference() {
        tz(-bottom) tube(id=BOLT_OD+SLOP2, od=HOUSING_OD, h=DRIVE_SLEEVE_B_FLANGE_SOCKET_T);
        // Bolt retainer slot
        cmy() ty((BOLT_OD/2)-BOLT_RETAINER_D) ty(-SLOP) translate([-(BOLT_RETAINER_T+SLOP2)/2,0,-$FOREVER/2]) cube([BOLT_RETAINER_T+SLOP2, BOLT_RETAINER_D*2+SLOP2, $FOREVER]);
      }
    }
    
    { // Slots
      // Drive gear slots
      slot_adjust = 1;
      tz(DRIVE_SLEEVE_A_SZ/2) crotate([0,0,180]) crotate([0,0,90]) translate((DRIVE_SLEEVE_A_OD/2+1-slot_adjust/2)*[1,1,0]) {
        house([4+slot_adjust,100,10]);
        houseCorner([4+slot_adjust,100,10]);
      }
      
      // Clutch gear slots
      slot2_oz = -0.7; //MISC Not sure where this number comes from; I just wanted the bottom to be flush with the floor
      tz(-3*INTERLOCK_SZ+slot2_oz/2) tz(DRIVE_SLEEVE_A_SZ/2) crotate([0,0,180]) crotate([0,0,90]) translate((DRIVE_SLEEVE_A_OD/2+4)*[1,1,0]) {
        house([5,100,14-slot2_oz]);
        rz(180) houseCorner([5,100,14-slot2_oz],bounds=40*SCALE);
      }
      
      // Drive Sleeve B access slots
      tz(-bottom+DRIVE_SLEEVE_B_FLANGE_SOCKET_T) crotate([0,0,90]) ty(-50) tx(-5) house([10,100,6], center=false);
    }
    
    union() { // Main chamber //RAINY Probably should just be built-in
      //THINK Should we add lateral/radial bracing at top/bottom of clutch sleeve?
      chamber_wall = 3;
      house_sx = HOUSING_OD-2*chamber_wall-CLUTCH_SLEEVE_OD;
      house_sz = SLOP+CLUTCH_SLEEVE_SZ+SLOP-(house_sx/2);
      tz(-bottom+DRIVE_SLEEVE_B_FLANGE_SOCKET_T+SLOP+DRIVE_SLEEVE_B_FLANGE_T+SLOP+DRIVE_SLEEVE_B_FLANGE_SOCKET_T) hull() rotate_extrude() {
        tx(-(HOUSING_OD/2)+chamber_wall) house2d([house_sx,house_sz],center=false);
      }
    }
    
    //RAINY ...This adds like 10% to the build time.  Sad.
    union() { // Decorative upper chamber
      chamber_wall = 2;
      house_sx = HOUSING_OD/2 - HOHLRAD_OD/2 - 2*chamber_wall;
      house_sz = SLOP+CLUTCH_SLEEVE_SZ+SLOP-(house_sx/2);
      tz(15) {
        rotate_extrude() {
          tx(-(HOUSING_OD/2)+chamber_wall) house2d([house_sx,house_sz],center=false);
        }
        tz(10) crz(30) crotate([
          [0,0,0*60],
          [0,0,1*60],
          [0,0,2*60],
          [0,0,3*60],
          [0,0,4*60],
          [0,0,5*60],
        ]) {
          window_depth = 30;
          ty(window_depth/2+HOUSING_OD/3) house([5,window_depth,10]);
        }
        tz(10) crotate([
          [0,0,0*120],
          [0,0,1*120],
          [0,0,2*120],
        ]) {
          window_depth = 30;
          ty(window_depth/2) house([5,window_depth,10]);
        }
      }
    }
  }
  
  // Clutch Intermediary rotation stops
  tz(-4*INTERLOCK_SZ+DRIVE_SLEEVE_B_FLANGE_T+SLOP) ClutchIntermediaryRotationStops(negative=false);
}

module ClutchIntermediaryRotationStops(negative=false) {
  center_d = CLUTCH_INTERMEDIARY_RIB_ID+CLUTCH_INTERMEDIARY_T;
  angle_oz = 2.15*INTERLOCK_SZ;
  negative_angle_slop = 360*SLOP/(2*PI*center_d/2);
  difference() {
    if (negative) {
      tube(id=center_d-CLUTCH_INTERMEDIARY_STOPS_T-SLOP2,od=center_d+CLUTCH_INTERMEDIARY_STOPS_T+SLOP2,h=angle_oz);
    } else {
      // Angled top supports
      tz(angle_oz) tube(id1=center_d-CLUTCH_INTERMEDIARY_STOPS_T,od1=center_d+CLUTCH_INTERMEDIARY_STOPS_T,id2=center_d-CLUTCH_INTERMEDIARY_STOPS_T+20,od2=center_d+CLUTCH_INTERMEDIARY_STOPS_T+20,h=10);
      
      // Straight bit
      tube(id=center_d-CLUTCH_INTERMEDIARY_STOPS_T,od=center_d+CLUTCH_INTERMEDIARY_STOPS_T,h=angle_oz);
    }
    nas = negative ? negative_angle_slop : 0;
    crotate([0,0,180]) crotate([0,0,90]) crotate([0,0,45]) rz(nas) difference() {
      OXp();
      rz((90/4)-2*nas) OXp();
    }
  }
}

module ClutchIntermediary() {
  rib_id = CLUTCH_INTERMEDIARY_RIB_ID;

  difference() {
    union() {
      // Ribbing
      difference() {
        tz(RIB_PITCH/2) cylinder(d=rib_id, h=INTERLOCK_SZ-RIB_PITCH);
        cylinder(d=HOHLRAD_OD+2*SLOP, h=INTERLOCK_SZ);
        ribbing(angle=RIB_ANGLE,pitch=RIB_PITCH,id=HOHLRAD_OD+2*SLOP,h=INTERLOCK_SZ);
        cylinder(d=HOHLRAD_OD);
      }
      
      difference() {
        thread_sz = INTERLOCK_SZ;
        tz(thread_sz/2) threaded_rod(d=rib_id+2*CLUTCH_INTERMEDIARY_T+2.5, l=thread_sz);
        cylinder(d=rib_id,h=$FOREVER,center=true);
      }
    }
    
    // Rotation stops
    ClutchIntermediaryRotationStops(negative=true);
  }
}

module ClutchSleeve() {
  rib_id = CLUTCH_INTERMEDIARY_RIB_ID;
  
  thread_id = CLUTCH_SLEEVE_THREAD_ID;  
  thread_sz = CLUTCH_SLEEVE_SZ;
  // Wall and inner threading
  difference() {
    cylinder(d=CLUTCH_SLEEVE_OD, h=thread_sz);
    tz(thread_sz/2) threaded_rod(d=thread_id, l=thread_sz);
  }
  
  // GT2 timing belt teeth
  tz(INTERLOCK_SZ-pulley_height()/2) {
    difference() {
      pulley("GT2 2mm", CLUTCH_SLEEVE_GT_OD, 0.764, 1.494, CLUTCH_SLEEVE_GT_TEETH, cutouts=false);
      cylinder(d=CLUTCH_SLEEVE_OD,h=$FOREVER,center=true);
    }
    mz() tube(id=CLUTCH_SLEEVE_OD,od1=CLUTCH_SLEEVE_GT_OD2,od2=CLUTCH_SLEEVE_OD,h=(CLUTCH_SLEEVE_GT_OD2-CLUTCH_SLEEVE_OD)/2);
  }
}

module DriveSleeveA() {
  difference() {
    union() {
      TransferHohlrad(sz=DRIVE_SLEEVE_A_SZ);
      
      // GT2 timing belt teeth
      difference() {
        pulley("GT2 2mm", DRIVE_SLEEVE_A_OD, 0.764, 1.494, DRIVE_SLEEVE_A_TEETH, cutouts=false);
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



DRIVE_SLEEVE_B_VSX = 2;
DRIVE_SLEEVE_B_VSY = $FOREVER;
DRIVE_SLEEVE_B_VSZ = 2;
DRIVE_SLEEVE_B_VSD = 3;

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
    vsx = DRIVE_SLEEVE_B_VSX;
    vsy = DRIVE_SLEEVE_B_VSY;
    vsz = DRIVE_SLEEVE_B_VSZ;
    vsd = DRIVE_SLEEVE_B_VSD;
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
module BoltRetainer(l=BOLT_RETAINER_TOP_L) {
  // Flange
  difference() {
    cylinder(d=BOLT_OD*1.5,h=NON_LOAD_T);
    cylinder(d=BOLT_OD+SLOP2,h=$FOREVER,center=true);
  }
  
  // Fins
  cmy() mz() ty((BOLT_OD/2)-BOLT_RETAINER_D) tx(-BOLT_RETAINER_T/2) tz(-NON_LOAD_T) cube([BOLT_RETAINER_T, BOLT_RETAINER_D*2, l+NON_LOAD_T]);
}

//RAINY This isn't handling slop correctly
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








// Assembly tools

TWISTER_FLANGE_TOP = DRIVE_SLEEVE_B_FLANGE_SOCKET_T+SLOP+DRIVE_SLEEVE_B_FLANGE_T;
TWISTER_HOLE_OZ = TWISTER_FLANGE_TOP-DRIVE_SLEEVE_B_FLANGE_T/2;
TWISTER_SZ = 2*TWISTER_HOLE_OZ;
TWISTER_MAIN_WALL = 23;
TWISTER_STICKOUT = TWISTER_MAIN_WALL;
TWISTER_STICKOUT_RADIUS = 10;
TWISTER_STICKOUT_WIDTH = 25;
TWISTER_ID = HOUSING_OD+2*SLOP2;
TWISTER_OD = TWISTER_ID+2*TWISTER_MAIN_WALL;
module Twister() {
  difference() {
    // Bulk
    tube(id=TWISTER_ID,wall=TWISTER_MAIN_WALL+TWISTER_STICKOUT,h=TWISTER_SZ);
    
    // Drive Sleeve B access slots
    vsx = DRIVE_SLEEVE_B_VSX;
    vsy = DRIVE_SLEEVE_B_VSY;
    vsz = DRIVE_SLEEVE_B_VSZ;
    vsd = DRIVE_SLEEVE_B_VSD;
    tz(TWISTER_HOLE_OZ) crotate([0,0,90]) cmy()
      ty(vsy/2) vslot([vsx,vsy,vsz]);
    tz(TWISTER_HOLE_OZ) crotate([0,0,90]) cmy()
      ty(TWISTER_ID/2 + TWISTER_MAIN_WALL) tz($FOREVER/2)
      ty(vsy/2) vslot([vsx,vsy,vsz+$FOREVER]);
    
    // Stickout cutouts
    minkowski() {
      difference() {
        tube(id=TWISTER_OD+2*TWISTER_STICKOUT_RADIUS,wall=$FOREVER,h=TWISTER_SZ);
        crz(90) cube([TWISTER_STICKOUT_WIDTH + 2*TWISTER_STICKOUT_RADIUS,$FOREVER,$FOREVER], center=true);
      }
      cylinder(r=TWISTER_STICKOUT_RADIUS,h=0.01,center=true,$fn=MKFN);
    }
  }
}
*tz(-HOUSING_BOTTOM) Twister();




module Assembly(engaged=true) {
  // Print each of these segments separately

  union() {
    tz(-2) Bolt();
  } 

  union() {
    Housing();
    DriveSleeveA();
    tz(-4*INTERLOCK_SZ) DriveSleeveB();
    tz(engaged ? SLOP : INTERLOCK_SZ) TransferSleeve();
    tz(-4*INTERLOCK_SZ+DRIVE_SLEEVE_B_FLANGE_T+SLOP) {
      tz(engaged ? SLOP : INTERLOCK_SZ) ClutchIntermediary();
      tz(SLOP) ClutchSleeve();
    }
  }
  
  union() {
    tz(4*INTERLOCK_SZ) BoltRetainer(BOLT_RETAINER_TOP_L);
  }
  
  union() {
    tz(-5*INTERLOCK_SZ-2.4) mz() BoltRetainer(BOLT_RETAINER_BOT_L);
  }
}


//BoltRetainer();
difference() {
  Assembly(engaged=true);
  //rz(45)
    OXpYm();
  //OZp([0,0,30]);
}

/*
timing teeth out
upper housing wall out
*/


