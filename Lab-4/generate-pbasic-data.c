/*
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 1000
#define ASCII_ZERO_CONVERSION 48

int log_base_two (int input) {
	int temp;
	for (temp = 0; input > (1 << temp); temp++) {}
	return temp;
}

int main (int argc, char* argv[])
{
	char rtttl_buffer[BUFFER_SIZE];
	int rtttl_size;
	int ret_val;
	int default_dur = 0;
	int default_oct = 0;
	int default_beat = 0;
	int note_buffer[BUFFER_SIZE];
	int note_buffer_size = 0;
	int note = 0;
	int sharp = 0;
	int duration = 0;
	int octave = 0;
	int dotted = 0;
	int data_buffer[BUFFER_SIZE];
	int data_buffer_size = 0;

	if (argc <= 1) {
		printf ("Usage: %s rtttl_file.txt\n", argv[0]); 
		exit (EXIT_FAILURE);
	}

	FILE* fp;
	fp = fopen (argv[1], "r");
	if (!fp) {
		printf ("Error: Could not find file %s\n", argv[1]);
	}

	for (rtttl_size = 0; rtttl_size < (BUFFER_SIZE-1); rtttl_size++) {
		ret_val = fscanf (fp, "%c", (rtttl_buffer + rtttl_size));
		if (ret_val == EOF)
			break;
		if (ret_val != 1) {
			printf ("Error reading RTTTL file: fscanf() returns %d\n", ret_val);
			exit (EXIT_FAILURE);
		}
	}
	rtttl_buffer[rtttl_size] = 0;
	fclose (fp);
	printf ("RTTTL Format:\n%s", rtttl_buffer);

	char* iter;
	iter = strstr (rtttl_buffer, "d=");
	if (!iter) {
		printf ("Error: default duration not found\n");
		exit(EXIT_FAILURE);
	}
	iter += 2;
	default_dur = *iter - ASCII_ZERO_CONVERSION;
	if (*(++iter) != ',') {
		default_dur *= 10;
		default_dur += *iter - ASCII_ZERO_CONVERSION;
	}
	printf ("Default Duration:\t%d\n", default_dur);	

	iter = strstr (rtttl_buffer, "o=");
	if (!iter) {
		printf ("Error: default octave not found\n");
		exit(EXIT_FAILURE);
	}
	default_oct = *(iter + 2) - ASCII_ZERO_CONVERSION;
	printf ("Default Octave:  \t%d\n", default_oct);	

	iter = strstr (rtttl_buffer, "b=");
	if (!iter) {
		printf ("Error: default beat not found\n");
		exit(EXIT_FAILURE);
	}
	for (iter = iter + 2; (*iter) != ':'; iter++) {
		if (!iter) {
			printf ("Error: default beat never ends...\n");
			exit (EXIT_FAILURE);
		}
		default_beat *= 10;
		default_beat += *iter - ASCII_ZERO_CONVERSION;
	}
	printf ("Default Beat:    \t%d\n", default_beat);	

	iter++;
	while (iter - rtttl_buffer < rtttl_size) {
		if (*iter < 'a') {
			duration = *(iter++) - ASCII_ZERO_CONVERSION;
			if (*iter < 'a') {
				duration *= 10;
				duration += *(iter++) - ASCII_ZERO_CONVERSION;
			}
		} 
		else
			duration = default_dur;
		duration = log_base_two (duration);
		if ((*iter < 'a') || (*iter > 'p')) {
			printf ("Error: at iter=%d, expecting letter between a-p\n", (int)(iter-rtttl_buffer));
			exit (EXIT_FAILURE);
		}
		if (*iter == 'p')
			note = 'h' - 'a', iter++;
		else
			note = *(iter++) - 'a';
		if (*iter == '#')
			sharp = 1, iter++;
		else
			sharp = 0;
		if (*iter == '.')
			dotted = 1, iter++;
		else
			dotted = 0;
		if ((*iter >= '4') && (*iter <= '7'))
			octave = *(iter++) - '4';
		else
			octave = default_oct;
		note_buffer[note_buffer_size] = (15 & duration) + (dotted << 3) + (note << 4) + (sharp << 7) + (octave << 8);
		if (*iter == ',')
			iter++, note_buffer_size++;
		else
			break;
	}

	printf ("Unpacked Data Array (starting with lowest bit of lowest byte) (size=%d):\n", note_buffer_size);
	for (int i=0; i<(note_buffer_size * 10); i++) {
		printf ("%d", ((note_buffer[i/10] >> (i%10))&1));
		if (i%8 == 7)
			printf ("|");	
	}

	for (int bit=0; bit < (note_buffer_size * 10); bit++) {
		data_buffer[bit/8] += ((note_buffer[bit/10] >> (bit%10))&1) << (bit % 8);
		if (0 == bit % 8)
			data_buffer_size++;
	}

	printf ("\nPacked Data Array: ([Beats per Minute][Total Notes][Byte 1][Byte 2]...[Byte N] where N = Total Notes * 10/8 rounded up)\n");
	printf ("%d, %d", default_beat, note_buffer_size);
	for (int i=0; i<data_buffer_size; i++)
		printf (", %d", (int) data_buffer[i]);
	printf ("\n");

	return 0;
}
