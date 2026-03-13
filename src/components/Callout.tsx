import React from 'react';
import { StyleSheet } from 'react-native';
import LuggCalloutViewNativeComponent from '../fabric/LuggCalloutViewNativeComponent';
import type { CalloutProps } from './Callout.types';

export type { CalloutProps } from './Callout.types';

export class Callout extends React.PureComponent<CalloutProps> {
  render() {
    const { onPress, children } = this.props;

    return (
      <LuggCalloutViewNativeComponent
        style={styles.callout}
        onCalloutPress={onPress ? () => onPress() : undefined}
      >
        {children}
      </LuggCalloutViewNativeComponent>
    );
  }
}

const styles = StyleSheet.create({
  callout: {
    position: 'absolute',
    pointerEvents: 'box-none',
  },
});
