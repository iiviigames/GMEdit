package yy;
import electron.FileSystem;
import electron.FileWrap;
import gml.Project;
import haxe.io.Path;
import js.Error;
import ui.GlobalSearch;

/**
 * ...
 * @author YellowAfterlife
 */
class YySearcher {
	public static function run(
		pj:Project, fn:ProjectSearcher, done:Void->Void, opt:GlobalSearchOpt
	):Void {
		var yyProject:YyProject = pj.readJsonFileSync(pj.name);
		var rxName = Project.rxName;
		var filesLeft = 1;
		inline function next():Void {
			if (--filesLeft <= 0) done();
		}
		function addError(s:String) {
			if (opt.errors != null) {
				opt.errors += "\n" + s;
			} else opt.errors = s;
		}
		for (resPair in yyProject.resources) {
			var res = resPair.Value;
			var resName:String, resFull:String;
			switch (res.resourceType) {
				case "GMScript": if (opt.checkScripts) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = Path.withoutExtension(res.resourcePath) + ".gml";
					filesLeft += 1;
					pj.readTextFile(resFull, function(error, code) {
						if (error == null) {
							var gml1 = fn(resName, resFull, code);
							if (gml1 != null && gml1 != code) {
								FileWrap.writeTextFileSync(resFull, gml1);
							}
						}
						next();
					});
				};
				case "GMObject": if (opt.checkObjects) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = res.resourcePath;
					filesLeft += 1;
					pj.readTextFile(resFull, function(error, data) {
						if (error == null) try {
							var resDir = Path.directory(resFull);
							var obj:YyObject = haxe.Json.parse(data);
							var code = obj.getCode(resFull);
							var gml1 = fn(resName, resFull, code);
							if (gml1 != null && gml1 != code) {
								if (obj.setCode(resFull, gml1)) {
									// OK!
								} else addError("Failed to modify " + resName
									+ ":\n" + YyObject.errorText);
							}
						} catch (_:Dynamic) { };
						next();
					});
				};
				case "GMTimeline": if (opt.checkObjects) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = res.resourcePath;
					filesLeft += 1;
					pj.readTextFile(resFull, function(error, data) {
						if (error == null) try {
							var resDir = Path.directory(resFull);
							var tl:YyTimeline = haxe.Json.parse(data);
							var code = tl.getCode(resFull);
							var gml1 = fn(resName, resFull, code);
							if (gml1 != null && gml1 != code) {
								if (tl.setCode(resFull, gml1)) {
									// OK!
								} else addError("Failed to modify " + resName
									+ ":\n" + YyObject.errorText);
							}
						} catch (_:Dynamic) { };
						next();
					});
				};
				case "GMShader": if (opt.checkShaders) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = Path.withoutExtension(res.resourcePath);
					inline function procShader(ext:String, type:String) {
						pj.readTextFile(resFull + "." + ext, function(error, code) {
							if (error == null) {
								var gml1 = fn(resName + '($type)', resFull, code);
								if (gml1 != null && gml1 != code) {
									FileWrap.writeTextFileSync(resFull, gml1);
								}
							}
							next();
						});
					}
					filesLeft += 2;
					procShader("fsh", "fragment");
					procShader("vsh", "vertex");
				};
				case "GMExtension": if (opt.checkExtensions) {
					resName = rxName.replace(res.resourcePath, "$1");
					resFull = res.resourcePath;
					filesLeft += 1;
					pj.readJsonFile(resFull, function(err, ext:YyExtension) {
						if (err != null) { next(); return; }
						var ext:YyExtension = FileWrap.readJsonFileSync(resFull);
						var extDir = Path.directory(resFull);
						for (file in ext.files) {
							var fileName = file.filename;
							if (Path.extension(fileName).toLowerCase() != "gml") continue;
							var filePath = Path.join([extDir, fileName]);
							filesLeft += 1;
							pj.readTextFile(filePath, function(err, code) {
								if (err != null) { next(); return; }
								var gml1 = fn(fileName, filePath, code);
								if (gml1 != null && gml1 != code) {
									FileWrap.writeTextFileSync(filePath, gml1);
								}
								next();
							});
						}
						next();
					});
				};
			}
		}
		next();
	}
}
