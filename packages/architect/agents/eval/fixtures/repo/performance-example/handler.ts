// Synthetic fixture. Same input contract and returned values as before.ts.
export function values(items: Array<{ visible: boolean; value: number }>) {
  const result: number[] = [];
  for (const item of items) {
    if (item.visible) result.push(item.value);
  }
  return result;
}
