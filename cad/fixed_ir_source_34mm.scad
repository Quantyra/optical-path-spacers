// Units: mm. Printable: source_stand, detector_cradle. Other selectors are illustrative proxies.
// Direct grooves, uniform recessed-seat upright, square wall/base junction.
$fn=40;
part="source_stand";
axis_z=20; foot_t=3; bore_d=3.4;
// Uniform wall, no lower block/heel. Front plane remains Y=+1.
plate_t=6; plate_front_y=1; wall_rear_y=plate_front_y-plate_t;
seat_land_t=1.4; flange_seat_y=plate_front_y-seat_land_t;
flange_clearance_d=4.4;
// Independent rectangular open channels, deliberately square at their junction.
lead_pitch=2.54; lead_slot_w=1.3; wall_groove_depth=0.8; base_groove_depth=0.8;
wall_floor_y=wall_rear_y+wall_groove_depth;
base_floor_z=foot_t-base_groove_depth;
// Unmeasured hardware PROXIES. The guide's 2 mm clearance is not a radius spec.
lead_proxy_d=0.8; flange_proxy_t=0.5; flange_proxy_d=3.85;
flange_axial_allowance=1; straight_min_design=2;
upper_bend_r=1.2; base_bend_r=1.2; arc_step=2;
seal_proxy_y=flange_seat_y-flange_proxy_t;
lead_wall_y=wall_floor_y-lead_proxy_d/2;
lead_base_z=base_floor_z+lead_proxy_d/2;
upper_start_y=lead_wall_y+upper_bend_r;
straight_near_seal=seal_proxy_y-upper_start_y;
base_cy=lead_wall_y-base_bend_r; base_cz=lead_base_z+base_bend_r;
assert(lead_pitch-lead_slot_w>=1.2,"Keep separating web >=1.2");
assert(plate_t-wall_groove_depth>=1.2 && seat_land_t>=1.2,"Keep wall/seat material");
assert(base_floor_z>=2,"Keep substantial base floor");
assert(flange_seat_y-flange_axial_allowance-upper_start_y>=straight_min_design-0.001,
       "Increase uniform wall thickness for actual flange/straight/bend requirements");
assert(flange_clearance_d>=4.1+0.3-0.001,"Flange loading clearance");
assert(lead_slot_w>lead_proxy_d && wall_groove_depth>=lead_proxy_d,"Slip groove envelope");
slot_front=-13; slot_rear=7; floor_z=8;
datum_inner_x=22.5; datum_outer_x=25;
datum_y_min=-6; datum_y_max=-2; datum_top_z=14;
assert(datum_inner_x>22,"Body side clearance");
assert(datum_y_min > -8.4 && datum_y_max < 2.4,"Panel corridors stay open");
assert(axis_z==floor_z+15-3,"V11 aperture height mismatch");
assert(slot_front < -12.4 && slot_rear > 6.4,"Full shell clearance");
module box(a,b){translate(a) cube(b-a);}
module across_x(points,half_w){
 multmatrix([[0,0,1,0],[1,0,0,0],[0,1,0,0],[0,0,0,1]])
  linear_extrude(2*half_w,center=true) polygon(points);
}
module roofed_circle(d,y0,y1){
 translate([0,(y0+y1)/2,axis_z]) rotate([90,0,0])
  linear_extrude(y1-y0,center=true)
   polygon(concat([for(a=[135:9:405]) [d/2*cos(a),d/2*sin(a)]],[[0,d/2*sqrt(2)]]));
}
module direct_groove(x){
 // One L-shaped cut: exact square root at [wall_floor_y,base_floor_z].
 // Upper end opens fully into the LED loading recess; no blind roof/lip.
 translate([x,0,0]) across_x([
  [-14.1,base_floor_z],[wall_floor_y,base_floor_z],
  [wall_floor_y,axis_z],[wall_rear_y-0.1,axis_z],
  [wall_rear_y-0.1,foot_t+0.1],[-14.1,foot_t+0.1]],lead_slot_w/2);
}
module source_stand(){
 difference(){
  union(){
   box([-17,-14,0],[17,14,foot_t]);
   box([-10,wall_rear_y,foot_t],[10,plate_front_y,25]);
   for(x=[-9,7]) translate([x,0,0]) rotate([90,0,90])
    linear_extrude(2) polygon([[0,foot_t],[10,foot_t],[0,13]]);
  }
  roofed_circle(bore_d,wall_rear_y-0.1,plate_front_y+0.1);
  // Rear-loaded seat; flange front rests on the 1.4 mm bore land at Y=-0.4.
  roofed_circle(flange_clearance_d,wall_rear_y-0.1,flange_seat_y);
  for(x=[-lead_pitch/2,lead_pitch/2]) direct_groove(x);
 }
}
// Two ordinary 90-degree conductor bends. CAD junction remains square.
function lead_route(x)=concat([[x,seal_proxy_y,axis_z]],
 [for(a=[0:arc_step:90])
  [x,upper_start_y-upper_bend_r*sin(a),axis_z-upper_bend_r+upper_bend_r*cos(a)]],
 [[x,lead_wall_y,base_cz]],
 [for(a=[arc_step:arc_step:90])
  [x,base_cy+base_bend_r*cos(a),base_cz-base_bend_r*sin(a)]],
 [[x,-14,lead_base_z]]);
module tube(points,d){
 // A simple swept proxy mesh keeps previews fast; no hardware STL is exported.
 n=16; m=len(points);
 pts=[for(i=[0:m-1]) let(
  v=points[min(i+1,m-1)]-points[max(i-1,0)],
  normal=[0,-v[2]/norm(v),v[1]/norm(v)])
  for(j=[0:n-1]) points[i]+[d/2*cos(360*j/n),0,0]+normal*d/2*sin(360*j/n)];
 faces=concat([[for(j=[n-1:-1:0]) j]],
  [for(i=[0:m-2]) for(j=[0:n-1]) each
   [[i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n],
    [i*n+j,(i+1)*n+(j+1)%n,(i+1)*n+j]]],
  [[for(j=[0:n-1]) (m-1)*n+j]]);
 polyhedron(pts,faces,convexity=10);
}
module led_proxy(){
 color("crimson") translate([0,flange_seat_y,axis_z]) rotate([-90,0,0]) cylinder(d=3,h=4.8);
 color("darkred") translate([0,seal_proxy_y,axis_z]) rotate([-90,0,0])
  cylinder(d=flange_proxy_d,h=flange_proxy_t);
 for(s=[-1,1]) color(s<0 ? "gold" : "silver") tube(lead_route(s*lead_pitch/2),lead_proxy_d);
}
module source_route_preview(){color("seagreen") source_stand(); led_proxy();}
module source_section_preview(){
 // Cut through positive lead center. Section is illustrative, not another part.
 color("seagreen") intersection(){source_stand();box([-17,-20,-1],[lead_pitch/2,15,26]);}
 led_proxy();
}
module source_entry_preview(){
 // Magnified cutaway of the real modeled seat/entry; hardware is illustrative.
 intersection(){source_section_preview();box([-17,-10,16],[17,8,25.5]);}
}
module detector_cradle(){
 union(){
  box([-25,-19,0],[25,13,floor_z]);
  box([-25,-19,floor_z-0.1],[25,slot_front,14]);
  box([-25,slot_rear,floor_z-0.1],[25,13,14]);
  // Fixed body-only datum tabs; 0.5 mm nominal gap, no clamping preload.
  for(side=[-1,1]) scale([side,1,1])
   box([datum_inner_x,datum_y_min,floor_z-0.1],
       [datum_outer_x,datum_y_max,datum_top_z]);
 }
}
// PROXY ONLY: V11 complete shell, shutter and cover envelopes. Not printable jig.
// Exact datum transform: original x,y,z -> world -x,-z,23-y.
module v11_pose(){translate([0,0,23]) rotate([0,180,0]) rotate([90,0,0]) children();}
module proxy_v11(offset=0){v11_pose(){
 color("slategray") difference(){
  union(){box([-22,-15,0],[22,15,8]);
   for(y=[-15,11.8]) box([-22,y,-6.4],[22,y+3.2,12.4]);}
  for(x=[-5,5]) translate([x,3,-7]) cylinder(d=2,h=21);
 }
 color("orange") translate([offset,0,0]) difference(){
  box([-34,-13,8.4],[22,13,10.4]);
  for(x=[-5,5]) translate([x,3,8]) cylinder(d=4,h=3);
 }
 color("gold") box([-28,-13,-4.4],[21,13,-2.4]);
 // Upward wire proxies, no polarity or channel assignment.
 color("silver") for(x=[-6.27,-3.73,3.73,6.27])
  box([x-0.25,-24,-1.4],[x+0.25,-14,-0.8]);
}}
source_x=0; // -5 left-body-edge, 0 centered, +5 right-body-edge registration
module assembly_preview(){
 color([0.6,0.5,0.35,0.25]) box([-65,-65,-2],[65,35,0]); // board proxy only
 color("teal") detector_cradle();
 proxy_v11();
 // Butted feet: local source +14 meets cradle -19; proxy lens gap 18.2.
 translate([source_x,-33,0]){
  color("seagreen") source_stand();
  led_proxy();
 }
 color([1,0,0,0.4]) translate([source_x,-28.6,axis_z]) rotate([-90,0,0]) cylinder(d=0.35,h=18.2);
}
if(part=="source_stand") source_stand();
else if(part=="detector_cradle") detector_cradle();
else if(part=="assembly") assembly_preview();
else if(part=="source_route") source_route_preview();
else if(part=="section") source_section_preview();
else if(part=="entry") source_entry_preview();
else assert(false,"Unknown part");
