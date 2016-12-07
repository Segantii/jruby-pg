REM -- target should not exist and jruby-complete-9.1.6.0.jar should be in the directory
rmdir /S /Q target
mkdir target
java -jar jruby-complete-9.1.6.0.jar -S ../errorcodes.rb ../errorcodes.txt Errors.java
javac Errors.java -cp jruby-complete-9.1.6.0.jar;. -Xlint:deprecation -d target 
dir /s /B *.java > sources.txt
javac @sources.txt -cp jruby-complete-9.1.6.0.jar;target;. -Xlint:deprecation -d target 
cd target 
jar cvf ../pg_ext.jar *
cd ..
