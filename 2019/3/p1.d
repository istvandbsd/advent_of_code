#!/usr/bin/env rdmd

import std.algorithm: map, sort;
import std.array;
import std.conv;
import std.math: abs;
import std.range: drop, takeExactly;
import std.stdio : File, writeln;
import std.string;


struct GridPoint {
    int x;
    int y;
}

alias GP = GridPoint;

auto add(GP pt1, GP pt2) {
    return GP(pt1.x+pt2.x, pt1.y+pt2.y);
}

auto manhattan(GP pt1, GP pt2) {
    return abs(pt1.x - pt2.x) + abs(pt1.y - pt2.y);
}

// this one should work as a "join" operation (of the fork/join lore)
auto section_offset(GP[] section, GP offset){
    // I'd like to see it as <array> + scalar = <array>
    // or maybe <array>.offset(scalar) = <array>
    return section.map!(pt => add(pt, offset)).array;
}

auto process_section(const char[] section) {
    GP[] coords = [];
    auto repeat = section[1..$].to!int; 
    switch (section[0]) {
        case 'L':
            foreach (r; 0..repeat+1) {
                coords ~= GP(-r,0); 
            }
            break;
        case 'R':
            foreach (r; 0..repeat+1) {
                coords ~= GP(r,0); 
            }            
            break;
        case 'U':
            foreach (r; 0..repeat+1) {
                coords ~= GP(0,r); 
            }            
            break;
        case 'D':
            foreach (r; 0..repeat+1) {
                coords ~= GP(0,-r); 
            }            
            break;
        default:
            // TODO throw exception (or do sthing else if we want nothrow)
            break;
    }
    return coords;
}

// alternatively: store only the segment endpoints and use a segment intersection algorithm
auto wire_coords(const char[][] wire_reading) {
    GP[] wire = [GP(0,0)];  // TODO efficiency: hashtable to emulate a set
    foreach (instr; wire_reading) {
        auto section_coords = process_section(instr)[1..$];  // TODO eliminate duplicates better?
        wire ~= section_coords.section_offset(wire[$-1]);
    }
    //writeln("Wire: ", wire);
    return wire;
}

auto wire_intersections(GP[] wire1, GP[] wire2) {  // TODO efficiency: hashtables
    GP[] intersections = [];
    // cannot use setops because the wire coordinates are not sorted
    foreach (coord1; wire1) {
        foreach (coord2; wire2) {
            if (coord1 == coord2) {
                intersections ~= coord1;
            }
        }
    }
    return intersections;
}

auto process_readings(const char[][][] wire_readings) {
    GP[][] coords = [];
    foreach (wire_reading; wire_readings){
        coords ~= wire_coords(wire_reading);
    }
    auto intersections = wire_intersections(coords[0], coords[1]);
    //writeln("Intersections: ", intersections);
    // TODO remove (0) better? also remove the first .array (.sort needs help :\)
    auto result = intersections.map!(a => manhattan(GP(0,0), a)).array.sort.drop(1).array;
    //writeln("Manhattans: ", result);
    return result[0];
}

void main() {
    auto input_file = File("input.txt", "r");
    scope(exit) input_file.close();
    auto wire_readings = input_file.byLine.takeExactly(2).map!(a => a.split(","));
    //writeln(wire_readings);
    // writeln(typeid(wire_readings)); // p1.main.MapResult!(__lambda1, ByLineImpl!(char, char)).MapResult // LOL
    writeln(process_readings(wire_readings.array));
}


unittest {
    auto input = [
        ["R5","D7","R4","U4"],
        ["U3","R3","D7","L2","U5"]
    ];
    GP[][] coords = [];
    foreach (wire_reading; input){
        coords ~= wire_coords(wire_reading);
    }
    auto expected = [GP(0,0), GP(1,0), GP(3,0)];
    auto result = wire_intersections(coords[0], coords[1]);
    //writeln(result);
    assert(result == expected);

}

// Test cases by AoC
unittest {
    auto input = [
        ["R75","D30","R83","U83","L12","D49","R71","U7","L72"],
        ["U62","R66","U55","R34","D71","R55","D58","R83"]
    ];
    auto expected = 159;
    auto result = process_readings(input);
    //writeln(result);
    assert(result == expected);
}

unittest {
    auto input = [
        ["R98","U47","R26","D63","R33","U87","L62","D20","R33","U53","R51"],
        ["U98","R91","D20","R16","D67","R40","U7","R15","U6","R7"]
    ];
    auto expected = 135;
    auto result = process_readings(input);
    //writeln(result);
    assert(result == expected);
}