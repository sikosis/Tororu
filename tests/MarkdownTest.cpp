#include "Markdown.h"

#include <cstdlib>
#include <iostream>
#include <string>

namespace {

void
ExpectContains(const std::string& html, const std::string& expected) {
	if (html.find(expected) != std::string::npos)
		return;
	std::cerr << "Missing converted Markdown: " << expected << '\n';
	std::exit(EXIT_FAILURE);
}
//---------------------------------------------------------------------------------------------------------------------------------//


} // namespace


int
main() {
	const std::string markdown
		= "# Tororu Markdown\n\n"
		"A **bold** and *italic* [link](page.html).\n\n"
		"> Quoted text\n\n"
		"- First item\n"
		"1. Numbered item\n\n"
		"---\n\n"
		"![Logo](logo.png) and `inline code`.\n\n"
		"```html\n<div>escaped</div>\n```\n";
	std::string html = MarkdownToHtml(markdown, "Guide.md");
	ExpectContains(html, "<title>Guide.md</title>");
	ExpectContains(html, "<h1>Tororu Markdown</h1>");
	ExpectContains(html, "<b>bold</b>");
	ExpectContains(html, "<i>italic</i>");
	ExpectContains(html, "<a href=\"page.html\">link</a>");
	ExpectContains(html, "<blockquote>Quoted text</blockquote>");
	ExpectContains(html, "<li>First item</li>");
	ExpectContains(html, "<li><b>1.</b> Numbered item</li>");
	ExpectContains(html, "<hr>");
	ExpectContains(html, "<img src=\"logo.png\" alt=\"Logo\">");
	ExpectContains(html, "<tt>inline code</tt>");
	ExpectContains(html, "<pre>&lt;div&gt;escaped&lt;/div&gt;\n</pre>");

	std::cout << "Markdown conversion tests passed\n";
	return EXIT_SUCCESS;
}
//---------------------------------------------------------------------------------------------------------------------------------//
