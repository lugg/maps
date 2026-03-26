import { StyleSheet, View } from 'react-native';

import { ThemedText } from '../components';
import { useTheme } from '../theme';

interface MarkerDetailScreenProps {
  name: string;
}

export const MarkerDetailScreen = ({ name }: MarkerDetailScreenProps) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <ThemedText style={styles.title}>{name}</ThemedText>
      <ThemedText variant="caption" style={styles.subtitle}>
        Marker detail screen
      </ThemedText>
      <ThemedText variant="caption" style={styles.hint}>
        Go back and press the same marker again
      </ThemedText>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  title: { fontSize: 24, fontWeight: 'bold' },
  subtitle: { fontSize: 16, marginTop: 8 },
  hint: { fontSize: 14, marginTop: 16 },
});
