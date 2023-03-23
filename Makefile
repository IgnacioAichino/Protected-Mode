
protected_mode.img: protected_mode.o linker.ld
	ld --oformat binary -o protected_mode.img -T linker.ld protected_mode.o
protected_mode.o: protected_mode.S
	as -g -o protected_mode.o protected_mode.S
clean:
	rm *.o *.img
qemu:
	qemu-system-x86_64 -hda protected_mode.img