//
//	container-resign
//	by staturnz @0x7FF7
//	02/22/23
//

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

extern char **environ;
void ldid(char* arg1, char* arg2) {
    pid_t pid = fork();
    if (pid == 0) {
		remove("/tmp/.container-resign.plist");
		int fd = open("/tmp/.container-resign.plist", O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
		dup2(fd, 1);
   		dup2(fd, 2);
		close(fd); 
        char *args[] = { "/usr/bin/ldid", arg1, arg2, NULL };
        execve("/usr/bin/ldid", args, environ);
        exit(-1);
    }

    usleep(1000000);
    waitpid(pid, NULL, 0);
}


void killall(char* arg1) {
    pid_t pid = fork();
    if (pid == 0) {
		char *args[] = { "/usr/bin/killall", arg1, NULL };
        execve("/usr/bin/killall", args, environ);
        exit(-1);
    }

    usleep(1000000);
    waitpid(pid, NULL, 0);
}


int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {

		if (getuid() != 0) {
			printf("[*] please run this command with root\n");
			return 1;
		}

		if (argc != 2) {
			printf("[*] usage: container-resign <path-to-binary>\n");
			return 1;
		}

   		if (access(argv[1], F_OK) != 0) {
			printf("[*] path to binary not found, please check your path\n");
			return 1;
		} 

		printf("[*] killing process if running\n");
		NSString *bin_path = [[@(argv[1]) lastPathComponent] stringByDeletingPathExtension];
		const char *bin_str = [bin_path UTF8String];
		killall((char*)bin_str);

		printf("[*] extracting current entitlements\n");
		ldid("-e", argv[1]);

		NSURL *url = [NSURL fileURLWithPath:@"/tmp/.container-resign.plist"];
		NSError *error;
		NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
		NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:&error];
		if (error) {
			printf("[*] failed to read plist\n");
			return 1;
		} 

		[dictionary setValue:@YES forKey:@"com.apple.private.security.no-container"];
		remove("/tmp/.container-resign.plist");

		printf("[*] saving temp entitlement file\n");
		[dictionary writeToFile:@"/tmp/ent.xml" atomically:YES];

		printf("[*] signing binary with new entitlements\n");
		ldid("-S/tmp/ent.xml", argv[1]);

		remove("/tmp/ent.xml");
		printf("[*] done!\n");
		return 0;
	}
}



