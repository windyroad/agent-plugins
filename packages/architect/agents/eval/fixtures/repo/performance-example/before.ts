// Synthetic fixture. Input is a validated dense JSON array of non-null records.
export function values(items: Array<{ visible: boolean; value: number }>) {
  return items.filter(item => item.visible).map(item => item.value);
}
