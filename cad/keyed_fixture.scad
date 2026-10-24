// SPDX-License-Identifier: CERN-OHL-S-2.0
// Quantyra / Daniel Eric Fredriksen baseline; see ATTRIBUTION.md.
// Millimetres. Only stand/cradle selectors are printable parts.
use <fixed_ir_source_34mm.scad>

part="stand";
station="left"; // View FROM source TOWARD jig: left=-world X, right=+world X.
petg_clearance=0.25; // EACH horizontal X flank.
socket_top_clearance=0.60; // Independent seated roof gap, all three stand pockets.
docking_foot_t=5; // Local front apron only; do not raise optics/rear lead grooves.
tongue_length=7;
tongue_h=1.4;
tongue_base_w=2.8;
tongue_top_w=4.8;
tip_leadin=1;
tip_narrow=0.6; // each side, only at tip
mouth_leadin=0.8;
mouth_extra=0.6; // each side at open mouth
end_clearance=0.4;
relief_w=8;
withdraw=0; // positive towards user (-world Y); 7.2 clears both tongues
source_x=station=="left" ? -5 : 5;
show_proxy=true;
$fn=40;

assert(station=="left" || station=="right");
assert(petg_clearance>=0.20 && petg_clearance<=0.30,
       "Reviewed parameter range: 0.20..0.30 mm per horizontal flank");
assert(tongue_length==7 && tongue_h==1.4 && tongue_base_w==2.8 && tongue_top_w==4.8,
       "Re-run geometry review if changing tongue proportions");
assert(docking_foot_t-tongue_h-socket_top_clearance>=3-0.001);
assert(socket_top_clearance==0.60 && docking_foot_t==5,
       "Re-run geometry review if changing the front apron or roof gap");

module block(lo,hi){translate(lo) cube(hi-lo);}
module xz_section(points,y0,y1){
 translate([0,y1,0]) rotate([90,0,0]) linear_extrude(y1-y0) polygon(points);
}
function tongue_section(n=0)=[[-tongue_base_w/2+n,0],
 [tongue_base_w/2-n,0],[tongue_top_w/2-n,tongue_h],
 [-tongue_top_w/2+n,tongue_h]];
module male_tongue(){
 // Flat sole, 35.5 degree outward growth from vertical; no support needed.
 xz_section(tongue_section(),-19-tongue_length+tip_leadin,-18.9);
 hull(){
  xz_section(tongue_section(tip_narrow),-19-tongue_length,-19-tongue_length+0.01);
  xz_section(tongue_section(),-19-tongue_length+tip_leadin-0.01,-19-tongue_length+tip_leadin);
 }
}
function socket_half(z,c,extra=0)=tongue_base_w/2+
 (tongue_top_w-tongue_base_w)/2/tongue_h*z+c+extra;
// Default preserves extension receivers; only the stand requests the taller void.
function socket_section(c,extra=0,top_clearance=undef)=
 let(z0=-0.1,z1=tongue_h+(is_undef(top_clearance) ? c : top_clearance))
 [[-socket_half(z0,c,extra),z0],[socket_half(z0,c,extra),z0],
 [socket_half(z1,c,extra),z1],[-socket_half(z1,c,extra),z1]];
module female_voids(c=petg_clearance){
 // Sole-open dovetail: full sloped flanks continue to Z=2, not a clipped roof.
 // Ceiling <=6.258 mm; flared mouth <=7.458; roof 3 mm; mouth webs >=2.271.
 xz_section(socket_section(c,0,socket_top_clearance),14-tongue_length-end_clearance,14.1);
 hull(){
  xz_section(socket_section(c,0,socket_top_clearance),14-mouth_leadin,14-mouth_leadin+0.01);
  xz_section(socket_section(c,mouth_extra,socket_top_clearance),14,14.1);
 }
 // Loose rectangular blind pockets, NOT additional captured sockets.
 // 8 mm roof bridges, 3 mm outer bearing strips; retain all butt faces above.
 for(x=[-10,10]) block([x-relief_w/2,14-tongue_length-end_clearance,-0.1],
                       [x+relief_w/2,14.1,tongue_h+socket_top_clearance]);
}
module keyed_stand(c=petg_clearance){
 difference(){
  union(){
   source_stand();
   // Add above the existing sole only in front of the upright. Rear grooves
   // end behind Y=-4.2; source seat and Z=20 axis remain untouched.
   block([-17,1,2.9],[17,14,docking_foot_t]);
  }
  female_voids(c);
 }
}
module port_labels(){
 // Additive letters on the front rail; outside the original jig slot/datum.
 for(i=[0,1]) translate([i==0 ? -5 : 5,-16,13.99])
  linear_extrude(0.41) text(i==0 ? "L" : "R",size=2.4,
                         font="Liberation Sans:style=Bold",halign="center",valign="center");
}
module keyed_cradle(){
 detector_cradle();
 for(x=[-5,5]) translate([x,0,0]) male_tongue();
 port_labels();
}
module placed_stand(x=source_x,t=withdraw,c=petg_clearance){
 translate([x,-33-t,0]) keyed_stand(c);
}
module fixture_scene(){
 color([0.10,0.40,0.53]) render(convexity=10) keyed_cradle();
 color([0.94,0.61,0.18]) render(convexity=10) placed_stand();
 if(show_proxy){proxy_v11();translate([source_x,-33-withdraw,0]) led_proxy();}
 color([0.95,0.12,0.12]) translate([source_x,-28.6-withdraw,20])
  rotate([-90,0,0]) cylinder(d=0.3,h=18.2+withdraw);
}

if(part=="stand") keyed_stand();
else if(part=="cradle") keyed_cradle();
else if(part=="assembly") fixture_scene();
else if(part=="underside"){
 color([0.94,0.61,0.18]) render(convexity=10) translate([0,0,3]) rotate([0,180,0]) keyed_stand();
}
else if(part=="detail"){
 color([0.94,0.61,0.18]) render(convexity=10) intersection(){placed_stand();block([-24,-29,-1],[24,-18,1.1]);}
 color([0.1,0.4,0.53]) render(convexity=10) intersection(){keyed_cradle();block([-24,-29,-1],[24,-16,3]);}
}
else if(part=="print"){
 color([0.94,0.61,0.18]) render(convexity=10) translate([-34,0,0]) keyed_stand();
 color([0.1,0.4,0.53]) render(convexity=10) translate([24,0,0]) keyed_cradle();
}
else assert(false,"Unknown selector");
