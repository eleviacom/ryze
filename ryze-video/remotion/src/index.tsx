import React from 'react';
import {registerRoot, Composition} from 'remotion';
import {RyzeVideo, DURATION, FPS, WIDTH, HEIGHT} from './Video';
import {RyzeKeynote, DURATION as KDUR, FPS as KFPS, WIDTH as KW, HEIGHT as KH} from './Keynote';
import {RyzeDeck} from './Deck';

export const Root: React.FC = () => (
  <>
    <Composition id="RyzeKeynote" component={RyzeKeynote} durationInFrames={KDUR} fps={KFPS} width={KW} height={KH} />
    <Composition id="RyzeDemo" component={RyzeVideo} durationInFrames={DURATION} fps={FPS} width={WIDTH} height={HEIGHT} />
    <Composition id="RyzeDeck" component={RyzeDeck} durationInFrames={10} fps={1} width={1920} height={1080} />
  </>
);

registerRoot(Root);
