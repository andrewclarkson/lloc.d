import std.stdio;
import std.file;
import std.getopt;
import std.parallelism;

/*
 * args[1] (optional): the path to explore
 * args[2] (optional): the pattern to match
 */

int count(string filename) {

    //the logical line counter
    int lines = 0;

    File file = File(filename, "r");

    string line;

    bool multi_line_comment = false;
    bool in_single_quotes = false;
    bool in_double_quotes = false;
    bool in_expression = false;

    // While we can read at least one byte
    while(file.readln(line)) {

        // multi-line comments take precedent over everything
        for(int i; i < line.length; i++) {
            if(multi_line_comment) {
                if(line[i] == '*' && line[i + 1] == '/') {
                    multi_line_comment = false;
                }
            } else {
                if(line[i] == '/' && line[i + 1] == '*') {
                    multi_line_comment = true;
                }

                if(line[i] == '/' && line[i + 1] == '/') {
                    break;
                }

                if(in_double_quotes && !in_single_quotes) {
                    if(line[i] == '"') {
                        in_double_quotes = false;
                    }
                } else {
                    if(line[i] == '"') {
                        in_double_quotes = true;
                    }

                    if(in_single_quotes && !in_double_quotes) {
                        if(line[i] == '\'') {
                            in_single_quotes = false;
                        }
                    } else {
                        if(line[i] == '\'') {
                            in_single_quotes = true;
                        }

                        if(in_expression) {
                            if(line[i] == ')') {
                                in_expression = false;
                            }
                        } else {
                            if(line[i] == '(') {
                                in_expression = true;
                            }

                            if(line[i] == ';' || line[i] == '{') {
                                lines++;
                            }
                        }
                    }
                }
            }
        }
    }
    return lines;
}

void main(string args[]) {

    string path = ".";
    string pattern;

    getopt(
        args,
        std.getopt.config.bundling,
        "path|p", &path,
        "pattern|e", &pattern
    );

    string files[];

    // if we have a pattern to match...
    if(pattern) {
        foreach(entry; dirEntries(path, "*.d", SpanMode.breadth, true)) {
            if(entry.isFile) {
                files ~= entry.name;
            }
        }
    } else {
        files = args[1..$];
    }

    int total = 0;

    foreach(file; taskPool.parallel(files)) {
        total += count(file);
    }

    writeln(total);

}
