import 'package:flutter/material.dart';
import '../../domain/entities/adoption.dart';

class AdoptionCard extends StatelessWidget {
  final Adoption adoption;
  const AdoptionCard({Key? key, required this.adoption}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet görseli için placeholder (ileride pet bilgisiyle doldurulabilir)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pets, size: 36, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet adı için ileride pet bilgisi çekilebilir
                  Text('Pet ID: ${adoption.petId}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Sahiplenen Kullanıcı ID: ${adoption.userId}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text('Tarih: ${adoption.adoptionDate.toLocal().toString().split(" ")[0]}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Detay sayfasına yönlendirme yapılabilir
                      },
                      child: const Text('Detay'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 