// pathfinder/shaders/gles2/mcaa-multi.vs.glsl
//
// Copyright (c) 2017 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

precision highp float;

uniform vec4 uTransformST;
uniform vec4 uHints;
uniform ivec2 uFramebufferSize;
uniform ivec2 uPathTransformSTDimensions;
uniform sampler2D uPathTransformST;
uniform ivec2 uPathColorsDimensions;
uniform sampler2D uPathColors;

attribute vec2 aQuadPosition;
attribute vec4 aUpperEndpointPositions;
attribute vec4 aLowerEndpointPositions;
attribute vec4 aControlPointPositions;
attribute float aPathID;

varying vec4 vUpperEndpoints;
varying vec4 vLowerEndpoints;
varying vec4 vControlPoints;
varying vec4 vColor;

void main() {
    vec2 tlPosition = aUpperEndpointPositions.xy;
    vec2 tcPosition = aControlPointPositions.xy;
    vec2 trPosition = aUpperEndpointPositions.zw;
    vec2 blPosition = aLowerEndpointPositions.xy;
    vec2 bcPosition = aControlPointPositions.zw;
    vec2 brPosition = aLowerEndpointPositions.zw;
    vec2 quadPosition = aQuadPosition;
    int pathID = int(aPathID);

    vec4 transformST = fetchFloat4Data(uPathTransformST, pathID, uPathTransformSTDimensions);

    vec4 color = fetchFloat4Data(uPathColors, pathID, uPathColorsDimensions);

    vec2 topVector = trPosition - tlPosition, bottomVector = brPosition - blPosition;
    float topTanTheta = topVector.y / topVector.x;
    float bottomTanTheta = bottomVector.y / bottomVector.x;

    // Transform the points, and compute the position of this vertex.
    tlPosition = computeMCAASnappedPosition(tlPosition,
                                            uHints,
                                            transformST,
                                            uTransformST,
                                            uFramebufferSize,
                                            topTanTheta);
    trPosition = computeMCAASnappedPosition(trPosition,
                                            uHints,
                                            transformST,
                                            uTransformST,
                                            uFramebufferSize,
                                            topTanTheta);
    tcPosition = computeMCAAPosition(tcPosition,
                                     uHints,
                                     transformST,
                                     uTransformST,
                                     uFramebufferSize);
    blPosition = computeMCAASnappedPosition(blPosition,
                                            uHints,
                                            transformST,
                                            uTransformST,
                                            uFramebufferSize,
                                            bottomTanTheta);
    brPosition = computeMCAASnappedPosition(brPosition,
                                            uHints,
                                            transformST,
                                            uTransformST,
                                            uFramebufferSize,
                                            bottomTanTheta);
    bcPosition = computeMCAAPosition(bcPosition,
                                     uHints,
                                     transformST,
                                     uTransformST,
                                     uFramebufferSize);

    float depth = convertPathIndexToViewportDepthValue(pathID);

    vec2 position;
    position.x = mix(tlPosition.x, brPosition.x, quadPosition.x);
    if (quadPosition.y < 0.5)
        position.y = floor(min(tlPosition.y, trPosition.y));
    else
        position.y = ceil(max(blPosition.y, brPosition.y));
    position = convertScreenToClipSpace(position, uFramebufferSize);

    gl_Position = vec4(position, depth, 1.0);
    vUpperEndpoints = vec4(tlPosition, trPosition);
    vLowerEndpoints = vec4(blPosition, brPosition);
    vControlPoints = vec4(tcPosition, bcPosition);
    vColor = color;
}