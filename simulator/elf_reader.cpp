#include <atomic>
#include <elf.h>
#include <fstream>
#include <iostream>
#include <vector>
#include <cstring>

extern "C" void write_mem(int addr, int data);

template <typename Elf_Ehdr, typename Elf_Shdr>
void extract_sections(std::ifstream &elf)
{
    Elf_Ehdr ehdr;
    elf.read(reinterpret_cast<char *>(&ehdr), sizeof(ehdr));

    // Leer tabla de secciones
    elf.seekg(ehdr.e_shoff, std::ios::beg);
    std::vector<Elf_Shdr> shdrs(ehdr.e_shnum);
    elf.read(reinterpret_cast<char *>(shdrs.data()),
             ehdr.e_shnum * sizeof(Elf_Shdr));

    // Leer string table de secciones
    Elf_Shdr shstr = shdrs[ehdr.e_shstrndx];
    std::vector<char> shstrtab(shstr.sh_size);
    elf.seekg(shstr.sh_offset, std::ios::beg);
    elf.read(shstrtab.data(), shstr.sh_size);

    for (size_t i = 0; i < shdrs.size(); ++i)
    {
        const Elf_Shdr &sh = shdrs[i];

        if (sh.sh_type == SHT_NOBITS || sh.sh_size == 0)
            continue;

        const char *name = &shstrtab[sh.sh_name];

        std::cout << "Sección: " << name
                  << " | Dirección inicio: 0x"
                  << std::hex << sh.sh_addr
                  << std::dec
                  << " | Tamaño: " << sh.sh_size << " bytes\n";

        // Leer contenido de la sección
        std::vector<char> data(sh.sh_size);
        elf.seekg(sh.sh_offset, std::ios::beg);
        elf.read(data.data(), sh.sh_size);

        std::cout << "Cargando sección " << name << " en memoria...\n";

        if (std::string(name) == ".text" || std::string(name) == ".data")
        {
            uint32_t addr = sh.sh_addr;
            uint32_t data_to_mem = 0;
            for (size_t offset = 0; offset < sh.sh_size; offset += 4)
            {
                std::memcpy(&data_to_mem, &data[offset], 4);
                write_mem(addr, data_to_mem);
                addr += 4;
            }

            if (sh.sh_size % 4 != 0)
            {
                uint32_t last_data = 0;
                size_t remaining = sh.sh_size % 4;
                std::memcpy(&last_data, &data[sh.sh_size - remaining], remaining);
                write_mem(addr, last_data);
            }
        }


        /*
        // Nombre del fichero
        std::string filename = std::string("seccion_") + name + ".bin";
        std::ofstream out(filename, std::ios::binary);

        if (!out)
        {
            std::cerr << "Error creando " << filename << "\n";
            continue;
        }

        out.write(data.data(), data.size());
        out.close();

        std::cout << "Extraída sección: " << name
                  << " (" << sh.sh_size << " bytes)\n";

                  */
    }
}

extern bool load_elf(const char *path)
{
    std::ifstream elf(path, std::ios::binary);
    if (!elf)
    {
        std::cerr << "Not able to open the file\n";
        return 1;
    }

    unsigned char ident[EI_NIDENT];
    elf.read(reinterpret_cast<char *>(ident), EI_NIDENT);

    if (ident[EI_MAG0] != ELFMAG0 ||
        ident[EI_MAG1] != ELFMAG1 ||
        ident[EI_MAG2] != ELFMAG2 ||
        ident[EI_MAG3] != ELFMAG3)
    {
        std::cerr << "Not a valid ELF\n";
        return false;
    }

    elf.seekg(0, std::ios::beg);

    if (ident[EI_CLASS] == ELFCLASS32)
    {
        extract_sections<Elf32_Ehdr, Elf32_Shdr>(elf);
    }
    else if (ident[EI_CLASS] == ELFCLASS64)
    {
        extract_sections<Elf64_Ehdr, Elf64_Shdr>(elf);
    }
    else
    {
        std::cerr << "Unknown ELF class\n";
        return false;
    }

    return true;
}

/*int main(int argc, char **argv)
{
    if (argc != 2)
    {
        std::cerr << "Uso: " << argv[0] << " <fichero.elf>\n";
        return 1;
    }

    std::ifstream elf(argv[1], std::ios::binary);
    if (!elf)
    {
        std::cerr << "No se puede abrir el fichero\n";
        return 1;
    }

    unsigned char ident[EI_NIDENT];
    elf.read(reinterpret_cast<char *>(ident), EI_NIDENT);

    if (ident[EI_MAG0] != ELFMAG0 ||
        ident[EI_MAG1] != ELFMAG1 ||
        ident[EI_MAG2] != ELFMAG2 ||
        ident[EI_MAG3] != ELFMAG3)
    {
        std::cerr << "No es un ELF válido\n";
        return 1;
    }

    elf.seekg(0, std::ios::beg);

    if (ident[EI_CLASS] == ELFCLASS32)
    {
        extract_sections<Elf32_Ehdr, Elf32_Shdr>(elf);
    }
    else if (ident[EI_CLASS] == ELFCLASS64)
    {
        extract_sections<Elf64_Ehdr, Elf64_Shdr>(elf);
    }
    else
    {
        std::cerr << "Clase ELF desconocida\n";
        return 1;
    }

    return 0;
}
*/
