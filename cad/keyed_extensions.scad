// SPDX-License-Identifier: CERN-OHL-S-2.0
// Quantyra / Daniel Eric Fredriksen. See ATTRIBUTION.md. Millimetres.
// Only part="extension" is a printable part; other modes illustrate assembly.
use <keyed_fixture.scad>
use <fixed_ir_source_34mm.scad>

part="extension";
L=100;                    // EXACT distance between stop planes, NOT STL length.
petg_clearance=0.25;       // horizontal per flank and seated gap above tongue
station="left";           // source toward detector: left=-X, right=+X
chain=[50,100];            // detector -> source order; preview only
withdraw=0;
$fn=40;
assert(L>=25 && L<=100,"Only 25..100 geometry domain; exported lengths 25,50,100");
assert(petg_clearance>=0.20 && petg_clearance<=0.30);
assert(station=="left" || station=="right");

// Local detector-facing stop Y=0, source-facing stop Y=-length; sole Z=0.
// No central receiving socket: only the -5 tongue locates the module.
module receiver_voids(c=petg_clearance){
 translate([-5,0,0]) {
  xz_section(socket_section(c),-7.4,0.1);
  hull(){
   xz_section(socket_section(c),-0.8,-0.79);
   xz_section(socket_section(c,0.6),0,0.1);
  }
 }
 block([1,-7.4,-0.1],[9,0.1,1.4+c]); // loose +5 pocket, 8 wide
}
module length_direction_label(length){
 translate([0,-length/2,3.99]) linear_extrude(0.41)
  text(str(length," mm"),size=3.1,font="Liberation Sans:style=Bold",
       halign="center",valign="center");
 translate([0,-3.9,3.99]) linear_extrude(0.41)
  text("DET",size=2.2,font="Liberation Sans:style=Bold",
       halign="center",valign="center");
 translate([11,-2.8,3.99]) linear_extrude(0.41)
  polygon([[-0.65,0],[0.65,0],[0.65,1.0],[1.5,1.0],[0,2.4],[-1.5,1.0],[-0.65,1.0]]);
}
module extension(length=L,c=petg_clearance){
 assert(length>=25 && length<=100);
 assert(c>=0.20 && c<=0.30);
 union(){
  difference(){block([-17,-length,0],[17,0,4]);receiver_voids(c);}
  // Direct reuse: exactly the original two 7 mm, 1.4-high tongues.
  for(x=[-5,5]) translate([x,19-length,0]) male_tongue();
  length_direction_label(length);
 }
}
function prefix_sum(a,i)=i<=0 ? 0 : a[i-1]+prefix_sum(a,i-1);
module assembled(lengths=[L]){
 total=prefix_sum(lengths,len(lengths));
 sx=station=="left" ? -5 : 5;
 color([0.10,0.40,0.53]) render(convexity=10) keyed_cradle();
 for(i=[0:len(lengths)-1])
  color(i%2==0 ? [0.26,0.63,0.47] : [0.36,0.57,0.79])
   render(convexity=10) translate([0,-19-prefix_sum(lengths,i),0])
    extension(lengths[i]);
 color([0.94,0.61,0.18]) render(convexity=10)
  translate([sx,-33-total-withdraw,0]) keyed_stand(petg_clearance);
 proxy_v11();
 translate([sx,-33-total-withdraw,0]) led_proxy();
 // Centreline illustration only; not a model of emitted beam width/power.
 color([0.92,0.10,0.14]) translate([sx,-28.6-total-withdraw,20])
  rotate([-90,0,0]) cylinder(d=0.35,h=18.2+total+withdraw);
}
if(part=="extension") extension();
else if(part=="assembly") assembled();
else if(part=="stack") assembled(chain);
else if(part=="underside") color([0.26,0.63,0.47]) render(convexity=10)
 translate([0,0,4.4]) rotate([0,180,0]) extension(25);
else if(part=="interface"){
 // Actual section through both engaged tongues, roof omitted above Z=1.1.
 color([0.10,0.40,0.53]) render(convexity=10)
  intersection(){keyed_cradle();block([-25,-27,0],[25,-17,1.1]);}
 color([0.26,0.63,0.47]) render(convexity=10)
  intersection(){translate([0,-19,0]) extension(25);block([-25,-29,0],[25,-17,1.1]);}
}
else if(part=="receiver_end") color([0.26,0.63,0.47]) render(convexity=10) extension(25);
else if(part=="print") for(i=[0:2])
 color([0.26,0.63,0.47]) render(convexity=10)
  translate([(i-1)*44,0,0]) extension([25,50,100][i]);
else assert(false,"Unknown selector");
