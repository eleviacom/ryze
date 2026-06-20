import React from 'react';
import {registerRoot, Composition} from 'remotion';
import {RyzeVideo, DURATION, FPS, WIDTH, HEIGHT} from './Video';

export const Root: React.FC = () => (
  <Composition
    id="RyzeDemo"
    component={RyzeVideo}
    durationInFrames={DURATION}
    fps={FPS}
    width={WIDTH}
    height={HEIGHT}
  />
);

registerRoot(Root);
