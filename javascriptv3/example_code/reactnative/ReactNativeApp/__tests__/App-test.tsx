/**
 * @format
 */

import 'react-native';
import React from 'react';
import App from '../App';

// Note: spec renderer must be required after react-native.
import renderer from 'react-spec-renderer';

it('renders correctly', () => {
  renderer.create(<App />);
});
