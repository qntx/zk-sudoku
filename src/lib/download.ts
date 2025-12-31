export const downloadFile = (content: string, filename: string): void => {
	const blob = new Blob([content], { type: 'application/json' });
	const url = URL.createObjectURL(blob);
	const link = Object.assign(document.createElement('a'), { href: url, download: filename });
	link.click();
	URL.revokeObjectURL(url);
};
