#include "Markdown.h"

#include <cctype>

namespace {

std::string
EscapeHtml(const std::string& text, bool attribute = false) {
	std::string escaped;
	for (char character : text) {
		switch (character) {
			case '&':
				escaped += "&amp;";
				break;
			case '<':
				escaped += "&lt;";
				break;
			case '>':
				escaped += "&gt;";
				break;
			case '"':
				escaped += attribute ? "&quot;" : "\"";
				break;
			default:
				escaped += character;
				break;
		}
	}
	return escaped;
}
//---------------------------------------------------------------------------------------------------------------------------------//


std::string
Trim(const std::string& text) {
	std::size_t start = 0;
	while (start < text.size()
		&& std::isspace(static_cast<unsigned char>(text[start]))) {
		++start;
	}
	std::size_t end = text.size();
	while (end > start
		&& std::isspace(static_cast<unsigned char>(text[end - 1]))) {
		--end;
	}
	return text.substr(start, end - start);
}
//---------------------------------------------------------------------------------------------------------------------------------//


std::string
InlineMarkdown(const std::string& text) {
	std::string html;
	std::size_t offset = 0;
	while (offset < text.size()) {
		if (text[offset] == '\\' && offset + 1 < text.size()) {
			html += EscapeHtml(text.substr(offset + 1, 1));
			offset += 2;
			continue;
		}
		if (text[offset] == '`') {
			std::size_t end = text.find('`', offset + 1);
			if (end != std::string::npos) {
				html += "<tt>";
				html += EscapeHtml(text.substr(offset + 1, end - offset - 1));
				html += "</tt>";
				offset = end + 1;
				continue;
			}
		}
		bool image = text[offset] == '!' && offset + 1 < text.size()
			&& text[offset + 1] == '[';
		if (image || text[offset] == '[') {
			std::size_t labelStart = offset + (image ? 2 : 1);
			std::size_t labelEnd = text.find("](", labelStart);
			std::size_t targetEnd = labelEnd == std::string::npos
				? std::string::npos : text.find(')', labelEnd + 2);
			if (targetEnd != std::string::npos) {
				std::string label = text.substr(labelStart, labelEnd - labelStart);
				std::string target = text.substr(labelEnd + 2,
					targetEnd - labelEnd - 2);
				if (image) {
					html += "<img src=\"" + EscapeHtml(target, true)
						+ "\" alt=\"" + EscapeHtml(label, true) + "\">";
				} else {
					html += "<a href=\"" + EscapeHtml(target, true) + "\">"
						+ InlineMarkdown(label) + "</a>";
				}
				offset = targetEnd + 1;
				continue;
			}
		}
		if ((text[offset] == '*' || text[offset] == '_')
			&& offset + 1 < text.size() && text[offset + 1] == text[offset]) {
			std::string marker(2, text[offset]);
			std::size_t end = text.find(marker, offset + 2);
			if (end != std::string::npos) {
				html += "<b>" + InlineMarkdown(text.substr(offset + 2,
					end - offset - 2)) + "</b>";
				offset = end + 2;
				continue;
			}
		}
		if (text[offset] == '*' || text[offset] == '_') {
			std::size_t end = text.find(text[offset], offset + 1);
			if (end != std::string::npos) {
				html += "<i>" + InlineMarkdown(text.substr(offset + 1,
					end - offset - 1)) + "</i>";
				offset = end + 1;
				continue;
			}
		}
		html += EscapeHtml(text.substr(offset, 1));
		++offset;
	}
	return html;
}
//---------------------------------------------------------------------------------------------------------------------------------//


bool
IsHorizontalRule(const std::string& line) {
	std::string compact;
	for (char character : line) {
		if (!std::isspace(static_cast<unsigned char>(character)))
			compact += character;
	}
	if (compact.size() < 3)
		return false;
	char marker = compact[0];
	if (marker != '-' && marker != '*' && marker != '_')
		return false;
	for (char character : compact) {
		if (character != marker)
			return false;
	}
	return true;
}
//---------------------------------------------------------------------------------------------------------------------------------//


} // namespace


std::string
MarkdownToHtml(const std::string& markdown, const std::string& title) {
	std::string html = "<html><head><title>" + EscapeHtml(title)
		+ "</title></head><body>\n";
	std::string paragraph;
	bool inFence = false;
	bool inList = false;

	auto flushParagraph = [&]() {
		if (paragraph.empty())
			return;
		html += "<p>" + InlineMarkdown(paragraph) + "</p>\n";
		paragraph.clear();
	};
	auto closeList = [&]() {
		if (!inList)
			return;
		html += "</ul>\n";
		inList = false;
	};

	std::size_t lineStart = 0;
	while (lineStart <= markdown.size()) {
		std::size_t lineEnd = markdown.find('\n', lineStart);
		if (lineEnd == std::string::npos)
			lineEnd = markdown.size();
		std::string line = markdown.substr(lineStart, lineEnd - lineStart);
		if (!line.empty() && line.back() == '\r')
			line.pop_back();
		std::string trimmed = Trim(line);

		if (trimmed.compare(0, 3, "```") == 0
			|| trimmed.compare(0, 3, "~~~") == 0) {
			flushParagraph();
			closeList();
			html += inFence ? "</pre>\n" : "<pre>";
			inFence = !inFence;
		} else if (inFence) {
			html += EscapeHtml(line) + "\n";
		} else if (trimmed.empty()) {
			flushParagraph();
			closeList();
		} else {
			std::size_t headingLevel = 0;
			while (headingLevel < trimmed.size() && headingLevel < 6
				&& trimmed[headingLevel] == '#') {
				++headingLevel;
			}
			if (headingLevel > 0 && headingLevel < trimmed.size()
				&& std::isspace(static_cast<unsigned char>(
					trimmed[headingLevel]))) {
				flushParagraph();
				closeList();
				std::size_t renderedLevel = headingLevel > 4 ? 4 : headingLevel;
				std::string level = std::to_string(renderedLevel);
				html += "<h" + level + ">"
					+ InlineMarkdown(Trim(trimmed.substr(headingLevel)))
					+ "</h" + level + ">\n";
			} else if (IsHorizontalRule(trimmed)) {
				flushParagraph();
				closeList();
				html += "<hr>\n";
			} else if (trimmed[0] == '>') {
				flushParagraph();
				closeList();
				html += "<blockquote>" + InlineMarkdown(Trim(trimmed.substr(1)))
					+ "</blockquote>\n";
			} else {
				bool unordered = trimmed.size() > 1
					&& (trimmed[0] == '-' || trimmed[0] == '*'
						|| trimmed[0] == '+')
					&& std::isspace(static_cast<unsigned char>(trimmed[1]));
				std::size_t orderedEnd = 0;
				while (orderedEnd < trimmed.size() && std::isdigit(
					static_cast<unsigned char>(trimmed[orderedEnd]))) {
					++orderedEnd;
				}
				bool ordered = orderedEnd > 0 && orderedEnd + 1 < trimmed.size()
					&& trimmed[orderedEnd] == '.' && std::isspace(
						static_cast<unsigned char>(trimmed[orderedEnd + 1]));
				if (unordered || ordered) {
					flushParagraph();
					if (!inList) {
						html += "<ul>\n";
						inList = true;
					}
					std::string item = unordered ? Trim(trimmed.substr(1))
						: Trim(trimmed.substr(orderedEnd + 1));
					html += "<li>";
					if (ordered)
						html += "<b>" + trimmed.substr(0, orderedEnd + 1)
							+ "</b> ";
					html += InlineMarkdown(item) + "</li>\n";
				} else {
					closeList();
					if (!paragraph.empty())
						paragraph += ' ';
					paragraph += trimmed;
				}
			}
		}

		if (lineEnd == markdown.size())
			break;
		lineStart = lineEnd + 1;
	}
	flushParagraph();
	closeList();
	if (inFence)
		html += "</pre>\n";
	html += "</body></html>";
	return html;
}
//---------------------------------------------------------------------------------------------------------------------------------//
